import SwiftUI
import UIKit
import DesignTokensKit
import UIComponentsKit
import LocalizationKit

private enum FeedBootPhase {
    case cold
    case preparing
    case ready
}

private struct CategoryTabItem: Identifiable {
    let key: CategoryKey?
    let title: String
    var id: String { key?.rawValue ?? "random" }
}

private struct FeedAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct HomeView: View {
    @AppStorage(AccentTheme.storageKey) private var accentThemeRawValue = AccentTheme.default.rawValue

    @StateObject private var quoteVM: QuoteViewModel
    @StateObject private var pageVM: FeedPageViewModel
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var cacheCoordinator = FeedCacheCoordinator()
    private let exportCoordinator = FeedExportCoordinator()

    @State private var showFavorites = false
    @State private var showShareSheet = false
    @State private var showAboutDeveloper = false
    @State private var sharingContent: FeedPageViewModel.FeedPageContent?

    @State private var selectedCategory: CategoryKey?
    @State private var selectedRatio: WallpaperAspectRatio = .fullScreen
    @State private var categories: [Category] = []

    @State private var scrollOffset: CGFloat = 0
    @State private var gestureStartOffset: CGFloat = 0
    @State private var activeDepth: Int = 0
    @State private var targetDepth: Int = 0
    @State private var isDragging: Bool = false
    @State private var isHorizontallyDragging: Bool = false
    @State private var bootPhase: FeedBootPhase = .cold

    @State private var currentDepth: Int = 0

    @State private var initialBootHasRun = false
    @State private var hasShownInitialConnectivityBanner = false
    @State private var showConnectivityBanner = false
    @State private var connectivityMessage = ""
    @State private var connectivityBannerIsWarning = false
    @State private var bannerHideTask: DispatchWorkItem?
    @State private var activeAlert: FeedAlert?
    @State private var randomQuoteCount: Int? = nil

    @State private var visualEffectsReduced = false
    @State private var visualEffectsRestoreTask: DispatchWorkItem?
    @Namespace private var categoryTabNamespace

    private let effectsRestoreDelay: TimeInterval = 0.08
    private let actionRailExclusionWidth: CGFloat = 132
    private let actionRailExclusionHeight: CGFloat = 320
    private let imageLoader: any ImageLoading

    init(quoteVM: QuoteViewModel, pageVM: FeedPageViewModel, imageLoader: (any ImageLoading)? = nil) {
        _quoteVM = StateObject(wrappedValue: quoteVM)
        _pageVM = StateObject(wrappedValue: pageVM)
        self.imageLoader = imageLoader ?? pageVM.imageLoader
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(\.black)
                .ignoresSafeArea()

            if bootPhase == .cold {
                Rectangle()
                    .fill(\.black)
                    .ignoresSafeArea()
            } else {
                pageContent
                    .gesture(feedSwipeGesture)
                    .simultaneousGesture(horizontalSwipeGesture)
            }
        }
        .background(\.black, ignoresSafeAreaEdges: .all)
        .task {
            await performInitialBootIfNeeded()
        }
        .fullScreenCover(isPresented: $showFavorites) {
            FavoritesView(quoteVM: quoteVM, imageLoader: imageLoader)
        }
        .sheet(isPresented: $showShareSheet, onDismiss: { sharingContent = nil }) {
            let activeContent = sharingContent ?? pageVM.current
            ShareImageQuoteView(
                favorite: nil,
                favoriteImage: nil,
                quote: activeContent?.quote,
                wallpaper: activeContent?.image,
                layoutSize: shareLayoutSize(),
                imageLoader: imageLoader
            )
        }
        .fullScreenCover(isPresented: $showAboutDeveloper) {
            AboutView()
        }
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(
                    \.ok,
                     action: {
                         activeAlert = nil
                     }
                )
            )
        }
        .onChange(of: pageVM.refreshError) { message in
            guard let message else { return }
            presentAlert(title: String(\MotivationStrings.refreshFailed), message: message)
            pageVM.refreshError = nil
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !hasShownInitialConnectivityBanner && bootPhase == .cold {
                return
            }
            updateConnectivityBanner(isConnected: isConnected, animated: true)
        }
        .onChange(of: activeDepth) { newDepth in
            prewarmWindow(around: selectedCategory, depth: newDepth, ratio: selectedRatio)
        }
        .onDisappear {
            bannerHideTask?.cancel()
            visualEffectsRestoreTask?.cancel()
            cacheCoordinator.cancelAllFetchTasks()
        }
        .safeAreaInset(edge: .top) {
            if bootPhase != .cold {
                topChrome
                    .transition(.opacity)
            }
        }
    }

    private var menuButton: some View {
        Menu {
            Menu(String(format: String(\MotivationStrings.themeMenu), locale: LocalizationController.shared.locale, selectedAccentTheme.localizedDisplayName)) {
                ForEach(AccentTheme.allCases) { theme in
                    Button(action: { selectAccentTheme(theme) }) {
                        menuItemLabel(title: theme.localizedDisplayName, isSelected: selectedAccentTheme == theme)
                    }
                }
            }

            Divider()

            Button(action: { showFavorites = true }) {
                Label(\.favourites, \.heartFill)
            }

            Button(action: { showAboutDeveloper = true }) {
                Label(\.aboutDeveloper, \.personCropCircle)
            }
        } label: {
            Image(\.menu)
                .font(\.title3)
                .foregroundColor(selectedAccentTheme.color)
                .accessibilityIdentifier(.contentMenuButton)
        }
    }

    private var headerOverlay: some View {
        categorySegmentedBar
    }

    private var topChrome: some View {
        VStack(spacing: \.eight) {
            ZStack {
                Text(\.motivationAppName)
                    .font(\.headline)
                    .minimumScaleFactor(\.p0_8)
                    .foregroundColor(selectedAccentTheme.color)

                HStack {
                    Rectangle()
                        .fill(\.clear)
                        .frame(width: \.p30, height: \.p30)
                    Spacer()
                    menuButton
                }
            }
            .padding(.horizontal, \.sixteen)
            .padding(.top, \.five)

            headerOverlay.frame(height: \.p55)
                .padding(.horizontal, \.twelve)

            if showConnectivityBanner {
                ConnectivityBannerView(
                    message: connectivityMessage,
                    isWarning: connectivityBannerIsWarning,
                    accent: selectedAccentTheme.color
                )
                .padding(.horizontal, \.twelve)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, \.eight)
        .background(
            LinearGradient(
                stops: [
                    ThemeColorStop(\.black, opacity: \.p0_9),
                    ThemeColorStop(\.ink, opacity: \.p0_85),
                    ThemeColorStop(\.clear)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var categorySegmentedBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: \.eight) {
                    ForEach(categoryTabs) { tab in
                        let isSelected = tab.key == selectedCategory
                        Button(action: { selectCategory(tab.key) }) {
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: \.sixteen)
                                        .fill(selectedAccentTheme.color.opacity(OpacityTheme.default.p0_25))
                                        .matchedGeometryEffect(id: "category-tab", in: categoryTabNamespace)
                                }

                                Text(tab.title)
                                    .font(\.footnote)
                                    .foregroundColor(isSelected ? selectedAccentTheme.color : ColorTheme.default.white.opacity(OpacityTheme.default.p0_7))
                                    .padding(.horizontal, \.twelve)
                                    .padding(.vertical, \.five)
                            }
                        }
                        .buttonStyle(.plain)
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, \.four)
            }
            .accessibilityIdentifier(.contentCategoryTabs)
            .onAppear {
                proxy.scrollTo(selectedCategory?.rawValue ?? "random", anchor: .center)
            }
            .onChange(of: selectedCategory) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(selectedCategory?.rawValue ?? "random", anchor: .center)
                }
            }
        }
    }

    private var categoryTabs: [CategoryTabItem] {
        var tabs: [CategoryTabItem] = [CategoryTabItem(key: nil, title: randomTabTitle)]
        tabs.append(contentsOf: categories.map { category in
            CategoryTabItem(key: category.key, title: categoryTitle(for: category))
        })
        return tabs
    }

    @ViewBuilder
    private func menuItemLabel(title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, \.checkmark)
        } else {
            Text(title)
        }
    }

    private var pageContent: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                feedCell(depth: activeDepth - 1, containerSize: geo.size, safeAreaInsets: geo.safeAreaInsets)
                    .offset(y: scrollOffset - h)

                feedCell(depth: activeDepth, containerSize: geo.size, safeAreaInsets: geo.safeAreaInsets)
                    .offset(y: scrollOffset)

                feedCell(depth: activeDepth + 1, containerSize: geo.size, safeAreaInsets: geo.safeAreaInsets)
                    .offset(y: scrollOffset + h)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .ignoresSafeArea()
    }

    private func feedCell(
        depth: Int,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> some View {
        let clamped = clampedDepth(depth, for: selectedCategory)
        let content = cachedContent(category: selectedCategory, depth: clamped, ratio: selectedRatio)

        return ZStack {
            if let content {
                renderedFeedPage(content: content, containerSize: containerSize, safeAreaInsets: safeAreaInsets)
            } else {
                pendingPlaceholderPage
                    .onAppear {
                        prewarmCell(category: selectedCategory, depth: clamped, ratio: selectedRatio)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func renderedFeedPage(
        content: FeedPageViewModel.FeedPageContent,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> some View {
        let imageRect = wallpaperRect(in: containerSize)
        let quoteLayout = QuoteCardLayout.style(for: imageRect)
        let quoteCardHeight = resolvedQuoteCardHeight(for: imageRect)

        return ZStack {
            Rectangle()
                .fill(\.black)
                .ignoresSafeArea()

            Image(uiImage: content.image)
                .resizable()
                .scaledToFill()
                .frame(width: imageRect.width, height: imageRect.height)
                .position(x: imageRect.midX, y: imageRect.midY)
                .clipped()

            GradientOverlayView(isReducedForScroll: visualEffectsReduced)

            QuoteCardContainerView(
                quote: content.quote,
                compactStyle: quoteLayout.isCompact,
                showsDepthEffects: !visualEffectsReduced,
                cardHeight: quoteCardHeight
            )
            .frame(width: quoteLayout.width, height: quoteCardHeight)
            .position(x: imageRect.midX, y: imageRect.midY)

            sideActionRail(for: content)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, \.sixteen)
                .padding(.bottom, max(safeAreaInsets.bottom + SpacingTheme.default.twentyFour, SpacingTheme.default.thirtyTwo))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pendingPlaceholderPage: some View {
        GeometryReader { proxy in
            let imageRect = wallpaperRect(in: proxy.size)
            let quoteLayout = QuoteCardLayout.style(for: imageRect)
            let quoteCardHeight = resolvedQuoteCardHeight(for: imageRect)

            ZStack {
                LinearGradient(
                    themeColors: [\.black, \.ink, \.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                RoundedRectangle(cornerRadius: quoteLayout.isCompact ? \.fourteen : \.twenty)
                    .fill(\.white, opacity: \.p0_1)
                    .overlay(
                        RoundedRectangle(cornerRadius: quoteLayout.isCompact ? \.fourteen : \.twenty)
                            .stroke(\.white, opacity: \.p0_18, lineWidth: \.one)
                    )
                    .frame(width: quoteLayout.width, height: quoteCardHeight)
                    .position(x: imageRect.midX, y: imageRect.midY)

                CenteredProgressOverlay(
                    width: nil,
                    background: \.clear
                )
                .tint(\.white, opacity: \.p0_9)
                .scaleEffect(ScaleToken.p1_0)
            }
        }
    }

    private var selectedCategoryTitle: String {
        guard let selectedCategory else { return String(\MotivationStrings.randomCategory) }
        return categories.first(where: { $0.key == selectedCategory })?.localizedDisplayName
            ?? selectedCategory.rawValue.capitalized
    }

    private var selectedAccentTheme: AccentTheme {
        AccentTheme.resolve(from: accentThemeRawValue)
    }

    private var feedSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard !isActionRailInteraction(at: value.startLocation) else {
                    return
                }
                if isHorizontallyDragging {
                    return
                }

                if !isDragging {
                    isDragging = true
                    gestureStartOffset = scrollOffset
                    reduceVisualEffectsForInteraction()
                }

                scrollOffset = gestureStartOffset + value.translation.height
            }
            .onEnded { value in
                if isHorizontallyDragging {
                    isHorizontallyDragging = false
                    return
                }

                isDragging = false
                guard !isActionRailInteraction(at: value.startLocation) else {
                    return
                }

                let velocity = value.velocity.height
                let projected = scrollOffset + project(velocity)

                let pageHeight = UIScreen.main.bounds.height
                let rawShift = Int(round(-projected / pageHeight))
                let indexShift = max(-1, min(1, rawShift))

                let proposedDepth = activeDepth + indexShift
                let clamped = clampedDepth(proposedDepth, for: selectedCategory)
                let maxDepth = maxDepth(for: selectedCategory)

                if proposedDepth != clamped {
                    if proposedDepth < 0 {
                        presentAlert(
                            title: String(\MotivationStrings.feedTopTitle),
                            message: String(\MotivationStrings.feedTopMessage)
                        )
                    } else if let maxDepth, proposedDepth > maxDepth {
                        presentAlert(
                            title: String(\MotivationStrings.feedEndTitle),
                            message: String(\MotivationStrings.feedEndMessage)
                        )
                    }
                } else if indexShift == 0 {
                    if activeDepth == 0, value.translation.height > 24 {
                        presentAlert(
                            title: String(\MotivationStrings.feedTopTitle),
                            message: String(\MotivationStrings.feedTopMessage)
                        )
                    } else if let maxDepth, activeDepth == maxDepth, value.translation.height < -24 {
                        presentAlert(
                            title: String(\MotivationStrings.feedEndTitle),
                            message: String(\MotivationStrings.feedEndMessage)
                        )
                    }
                }

                targetDepth = clamped
                snapToDepth(targetDepth)
            }
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isActionRailInteraction(at: value.startLocation) else {
                    return
                }
                if !isHorizontallyDragging && abs(value.translation.width) > abs(value.translation.height) {
                    isHorizontallyDragging = true
                }
            }
            .onEnded { value in
                guard !isActionRailInteraction(at: value.startLocation) else {
                    return
                }
                if isHorizontallyDragging {
                    let vx = value.velocity.width
                    let projected = value.translation.width + project(vx)

                    if projected <= -40 {
                        goToNextCategory()
                    } else if projected >= 40 {
                        goToPreviousCategory()
                    }
                    isHorizontallyDragging = false
                }
            }
    }

    func project(_ velocity: CGFloat) -> CGFloat {
        velocity * 0.32
    }

    private func snapToDepth(_ depth: Int) {
        let pageHeight = UIScreen.main.bounds.height
        let destination = -CGFloat(depth - activeDepth) * pageHeight

        withAnimation(.interpolatingSpring(stiffness: 420, damping: 42)) {
            scrollOffset = destination
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            activeDepth = depth
            currentDepth = depth
            scrollOffset = 0
            loadCurrentCoordinate(forceFetch: false)
            prewarmWindow(around: selectedCategory, depth: activeDepth, ratio: selectedRatio)
            scheduleVisualEffectsRestore()
        }
    }

    func wallpaperRect(in container: CGSize) -> CGRect {
        wallpaperRect(in: container, ratio: selectedRatio)
    }

    func wallpaperRect(in container: CGSize, ratio: WallpaperAspectRatio) -> CGRect {
        guard container.width > 0, container.height > 0 else { return .zero }
        guard let ratioValue = ratio.value else {
            return CGRect(origin: .zero, size: container)
        }

        let width = container.width
        let height = width / max(ratioValue, 0.01)
        return CGRect(
            x: 0,
            y: (container.height - height) / 2.0,
            width: width,
            height: height
        )
    }

    private func sideActionRail(for content: FeedPageViewModel.FeedPageContent) -> some View {
        let quote = content.quote
        let isSaved = quoteVM.isFavorited(quote: quote)

        return VStack(spacing: \.fourteen) {
            Menu {
                ForEach(WallpaperAspectRatio.allCases) { ratio in
                    Button(action: { selectRatio(ratio) }) {
                        if ratio == selectedRatio {
                            Label(ratio.localizedTitle, \.checkmark)
                        } else {
                            Text(ratio.localizedTitle)
                        }
                    }
                }
            } label: {
                SideActionIconView(
                    \.crop,
                    label: selectedRatio.localizedTitle
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.contentRatioButton)

            Button(action: {
                toggleFavorite(for: content)
            }) {
                SideActionIconView(
                    isSaved ? \.heartFill : \.heart,
                    isSaved ? \.saved : \.saveToPhotos,
                    tint: isSaved ? \.red : \.white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.contentSaveButton)

            Button(action: {
                sharingContent = content
                showShareSheet = true
            }) {
                SideActionIconView(
                    \.share,
                    \.share
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.contentShareButton)
        }
    }

    private func toggleFavorite(for content: FeedPageViewModel.FeedPageContent) {
        let quote = content.quote
        if quoteVM.isFavorited(quote: quote) {
            quoteVM.removeFromFavorites(quote: quote)
            return
        }

        Task {
            let localImageData = await exportCoordinator.prepareFavoriteImageData(
                for: content,
                imageLoader: imageLoader
            )
            let requestSize = pageVM.imageRequestSize(for: selectedRatio)
            await MainActor.run {
                guard let localImageData, !localImageData.isEmpty else {
                    pageVM.refreshError = String(\MotivationStrings.shareImagePreparing)
                    return
                }
                quoteVM.addToFavorites(
                    quote,
                    imageURL: content.imageURL,
                    localImageData: localImageData,
                    ratioRawValue: selectedRatio.rawValue,
                    imageWidth: requestSize.width,
                    imageHeight: requestSize.height
                )
            }
        }
    }

    private func selectAccentTheme(_ theme: AccentTheme) {
        accentThemeRawValue = theme.rawValue
    }

    private func selectCategory(_ key: CategoryKey?) {
        selectedCategory = key
        let lane = laneKey(category: key, ratio: selectedRatio)
        activeDepth = clampedDepth(cacheCoordinator.depthByLane[lane] ?? 0, for: key)
        targetDepth = activeDepth
        currentDepth = activeDepth
        cacheCoordinator.depthByLane[lane] = activeDepth
        scrollOffset = 0
        let hasCachedTarget = cachedContent(category: key, depth: activeDepth, ratio: selectedRatio) != nil
        loadCurrentCoordinate(forceFetch: !hasCachedTarget)
    }

    private func updateConnectivityBanner(isConnected: Bool, animated: Bool) {
        bannerHideTask?.cancel()

        let applyState = {
            if isConnected {
                connectivityBannerIsWarning = false
                connectivityMessage = String(\MotivationStrings.connectivityConnected)
                showConnectivityBanner = true
            } else {
                connectivityBannerIsWarning = true
                connectivityMessage = String(\MotivationStrings.connectivityOffline)
                showConnectivityBanner = true
            }
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                applyState()
            }
        } else {
            applyState()
        }

        guard isConnected else { return }

        let hideTask = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                showConnectivityBanner = false
            }
        }
        bannerHideTask = hideTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: hideTask)
    }

    private func selectRatio(_ ratio: WallpaperAspectRatio) {
        guard selectedRatio != ratio else { return }

        let previousCoord = coordinate(category: selectedCategory, depth: currentDepth, ratio: selectedRatio)
        let currentContent = cacheCoordinator.pageCache[previousCoord] ?? pageVM.current

        selectedRatio = ratio
        scrollOffset = 0
        reduceVisualEffectsForInteraction()

        let nextLane = laneKey(category: selectedCategory, ratio: ratio)
        let nextDepth = clampedDepth(currentDepth, for: selectedCategory)
        currentDepth = nextDepth
        activeDepth = nextDepth
        cacheCoordinator.depthByLane[nextLane] = nextDepth
        let nextCoord = FeedCoordinate(lane: nextLane, depth: nextDepth)
        if let currentContent {
            let adaptedContent = adaptContent(currentContent, for: ratio)
            cacheCoordinator.pageCache[nextCoord] = adaptedContent
            pageVM.applyCached(adaptedContent)
        }

        adaptCachedPages(for: ratio)
        pruneRenderWindow()
        scheduleVisualEffectsRestore()
    }

    func minimumQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? 160 : 220
    }

    func preferredQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? 248 : 320
    }

    func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let availableHeight = max(imageRect.height - 12, 1)
        let minimumHeight = minimumQuoteCardHeight(for: imageRect)
        let preferredHeight = preferredQuoteCardHeight(for: imageRect)
        return min(preferredHeight, max(availableHeight, minimumHeight))
    }

    func laneKey(category: CategoryKey?, ratio: WallpaperAspectRatio) -> FeedLaneKey {
        cacheCoordinator.laneKey(category: category, ratio: ratio, pageVM: pageVM)
    }

    func coordinate(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) -> FeedCoordinate {
        cacheCoordinator.coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }

    func categoryFromRaw(_ rawValue: String) -> CategoryKey? {
        rawValue == "random" ? nil : CategoryKey(rawValue: rawValue)
    }

    private func loadCurrentCoordinate(
        forceFetch: Bool,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil
    ) {
        cacheCoordinator.navigateTo(
            category: selectedCategory,
            depth: currentDepth,
            ratio: selectedRatio,
            forceFetch: forceFetch,
            quoteOverride: quoteOverride,
            minimumLoaderDuration: minimumLoaderDuration,
            pageVM: pageVM,
            isConnected: networkMonitor.isConnected,
            categories: categories,
            onFailure: {
                scheduleVisualEffectsRestore()
            }
        )
    }

    func cachedContent(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent? {
        cacheCoordinator.cachedContent(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }

    @MainActor
    private func performInitialBootIfNeeded() async {
        guard !initialBootHasRun else { return }
        initialBootHasRun = true

        pageVM.warmupCatalogue()
        await loadCategoriesIfNeeded()

        withAnimation(.easeOut(duration: 0.2)) {
            bootPhase = .preparing
        }

        if !hasShownInitialConnectivityBanner {
            hasShownInitialConnectivityBanner = true
            updateConnectivityBanner(isConnected: networkMonitor.isConnected, animated: false)
        }
        activeDepth = clampedDepth(currentDepth, for: selectedCategory)
        targetDepth = activeDepth
        currentDepth = activeDepth
        loadCurrentCoordinate(forceFetch: false, minimumLoaderDuration: 0.35)
    }

    private func isActionRailInteraction(at startLocation: CGPoint) -> Bool {
        let bounds = UIScreen.main.bounds
        let minX = bounds.width - actionRailExclusionWidth
        let minY = bounds.height - actionRailExclusionHeight
        return startLocation.x >= minX && startLocation.y >= minY
    }

    private func reduceVisualEffectsForInteraction() {
        visualEffectsRestoreTask?.cancel()
        visualEffectsRestoreTask = nil
        visualEffectsReduced = true
    }

    private func scheduleVisualEffectsRestore() {
        visualEffectsRestoreTask?.cancel()
        let restoreTask = DispatchWorkItem {
            visualEffectsReduced = false
        }
        visualEffectsRestoreTask = restoreTask
        DispatchQueue.main.asyncAfter(deadline: .now() + effectsRestoreDelay, execute: restoreTask)
    }

    private func prewarmWindow(around category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) {
        cacheCoordinator.prewarmWindow(
            around: category,
            depth: depth,
            ratio: ratio,
            categories: categories,
            pageVM: pageVM,
            isConnected: networkMonitor.isConnected
        )
    }

    func surroundingCategories(around center: CategoryKey?, radius: Int) -> [CategoryKey?] {
        cacheCoordinator.surroundingCategories(around: center, in: categories, radius: radius)
    }

    func surroundingDepths(around center: Int, radius: Int) -> [Int] {
        cacheCoordinator.surroundingDepths(around: center, radius: radius)
    }

    private func prewarmCell(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) {
        cacheCoordinator.prewarmCell(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }

    func pruneRenderWindow() {
        cacheCoordinator.pruneRenderWindow(
            selectedCategory: selectedCategory,
            selectedRatio: selectedRatio,
            currentDepth: currentDepth,
            categories: categories,
            pageVM: pageVM
        )
    }

    private func clearLaneCache(category: CategoryKey?, ratio: WallpaperAspectRatio) {
        cacheCoordinator.clearLaneCache(category: category, ratio: ratio, pageVM: pageVM)
    }

    private func loadCategoriesIfNeeded() async {
        guard categories.isEmpty else { return }
        let fallback: [Category]
        do {
            fallback = try await quoteVM.fetchCategories()
        } catch {
            fallback = []
        }

        categories = await pageVM.categories(fallback: fallback)
        randomQuoteCount = await pageVM.randomQuoteCount()
        let clamped = clampedDepth(currentDepth, for: selectedCategory)
        if clamped != currentDepth {
            currentDepth = clamped
            cacheCoordinator.depthByLane[laneKey(category: selectedCategory, ratio: selectedRatio)] = clamped
        }
    }

    func categoryTitle(for category: Category) -> String {
        guard let quoteCount = category.quoteCount else {
            return category.localizedDisplayName
        }
        return "\(category.localizedDisplayName) (\(quoteCount))"
    }

    var randomTabTitle: String {
        if let randomQuoteCount {
            return "\(String(\MotivationStrings.randomCategory)) (\(randomQuoteCount))"
        }
        return String(\MotivationStrings.randomCategory)
    }

    func maxDepth(for category: CategoryKey?) -> Int? {
        cacheCoordinator.maxDepth(for: category, in: categories)
    }

    func clampedDepth(_ depth: Int, for category: CategoryKey?) -> Int {
        cacheCoordinator.clampedDepth(depth, for: category, in: categories)
    }

    private func presentAlert(title: String, message: String) {
        activeAlert = FeedAlert(title: title, message: message)
    }

    func shareLayoutSize() -> CGSize {
        exportCoordinator.shareLayoutSize(for: selectedRatio, using: pageVM)
    }

    func adaptContent(
        _ content: FeedPageViewModel.FeedPageContent,
        for ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent {
        cacheCoordinator.adaptContent(content, for: ratio)
    }

    func adaptCachedPages(for ratio: WallpaperAspectRatio) {
        cacheCoordinator.adaptCachedPages(for: ratio)
    }

    func cropImage(_ image: UIImage, toAspect aspect: CGFloat) -> UIImage {
        cacheCoordinator.cropImage(image, toAspect: aspect)
    }

    func normalizedImage(_ image: UIImage) -> UIImage {
        cacheCoordinator.normalizedImage(image)
    }

    // MARK: - Navigation helpers for horizontal swipe gesture

    private func allCategoryKeys() -> [CategoryKey?] {
        [nil] + categories.map { $0.key }
    }

    private func selectAdjacentCategory(direction: Int) {
        let keys = allCategoryKeys()
        guard !keys.isEmpty else { return }

        let currentIndex = keys.firstIndex { $0 == selectedCategory } ?? 0
        var next = currentIndex + direction
        while next < 0 {
            next += keys.count
        }
        while next >= keys.count {
            next -= keys.count
        }

        selectCategory(keys[next])
    }

    private func goToNextCategory() {
        selectAdjacentCategory(direction: 1)
    }

    private func goToPreviousCategory() {
        selectAdjacentCategory(direction: -1)
    }
}

#Preview {
    let container = AppContainer.preview
    HomeView(
        quoteVM: container.makeQuoteViewModel(),
        pageVM: container.makeFeedPageViewModel()
    )
}
