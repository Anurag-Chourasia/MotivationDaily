import SwiftUI
import UIKit

private enum FeedBootPhase {
    case cold
    case preparing
    case ready
}

private struct FeedLaneKey: Hashable {
    let categoryRawValue: String
    let ratioRawValue: String
    let imageWidth: Int
    let imageHeight: Int
}

private struct FeedCoordinate: Hashable {
    let lane: FeedLaneKey
    let depth: Int
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

    @State private var showFavorites = false
    @State private var showShareSheet = false
    @State private var showAboutDeveloper = false

    @State private var selectedCategory: CategoryKey?
    @State private var selectedRatio: WallpaperAspectRatio = .fullScreen
    @State private var categories: [Category] = []

    @State private var scrollOffset: CGFloat = 0
    @State private var gestureStartOffset: CGFloat = 0
    @State private var activeDepth: Int = 0
    @State private var targetDepth: Int = 0
    @State private var isDragging: Bool = false
    @State private var bootPhase: FeedBootPhase = .cold

    @State private var pageCache: [FeedCoordinate: FeedPageViewModel.FeedPageContent] = [:]
    @State private var depthByLane: [FeedLaneKey: Int] = [:]
    @State private var visitedDepthsByLane: [FeedLaneKey: [Int]] = [:]
    @State private var currentDepth: Int = 0
    @State private var ratioQuoteOverrides: [FeedCoordinate: Quote] = [:]
    @State private var prewarmInFlight: Set<FeedCoordinate> = []
    @State private var activeFetchTasks: [FeedCoordinate: Task<Void, Never>] = [:]

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

    private let verticalRenderRadius = 1
    private let horizontalRenderRadius = 1
    private let effectsRestoreDelay: TimeInterval = 0.08
    private let prewarmDepthRadius = 2
    private let maxPrewarmInFlightCount = 3
    private let actionRailExclusionWidth: CGFloat = 132
    private let actionRailExclusionHeight: CGFloat = 320
    private let visitedDepthLimit = 120

    init(quoteVM: QuoteViewModel, pageVM: FeedPageViewModel) {
        _quoteVM = StateObject(wrappedValue: quoteVM)
        _pageVM = StateObject(wrappedValue: pageVM)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if bootPhase == .cold {
                Color.black.ignoresSafeArea()
            } else {
                pageContent
                    .contentShape(Rectangle())
                    .gesture(feedSwipeGesture)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await performInitialBootIfNeeded()
        }
        .fullScreenCover(isPresented: $showFavorites) {
            FavoritesView(quoteVM: quoteVM)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareImageQuoteView(
                favorite: nil,
                favoriteImage: nil,
                quote: pageVM.current?.quote,
                wallpaper: pageVM.current?.image,
                layoutSize: shareLayoutSize()
            )
        }
        .fullScreenCover(isPresented: $showAboutDeveloper) {
            AboutView()
        }
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: pageVM.refreshError) { message in
            guard let message else { return }
            presentAlert(title: "Refresh Failed", message: message)
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
            for task in activeFetchTasks.values {
                task.cancel()
            }
            activeFetchTasks.removeAll()
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
            Menu("Accent: \(selectedAccentTheme.displayName)") {
                ForEach(AccentTheme.allCases) { theme in
                    Button(action: { selectAccentTheme(theme) }) {
                        menuItemLabel(title: theme.displayName, isSelected: selectedAccentTheme == theme)
                    }
                }
            }

            Divider()

            Button(action: { showFavorites = true }) {
                Label("Favourites", systemImage: "heart.fill")
            }

            Button(action: { showAboutDeveloper = true }) {
                Label("About Developer", systemImage: "person.crop.circle")
            }
        } label: {
            Image(systemName: "line.3.horizontal.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(selectedAccentTheme.color)
                .accessibilityIdentifier("content.menuButton")
        }
    }

    private var headerOverlay: some View {
        categorySegmentedBar
    }

    private var topChrome: some View {
        VStack(spacing: 8) {
            ZStack {
                Text("MotivationDaily")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .foregroundColor(selectedAccentTheme.color)

                HStack {
                    Color.clear
                        .frame(width: 28, height: 28)
                    Spacer()
                    menuButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            headerOverlay.frame(height: 56)
                .padding(.horizontal, 12)

            if showConnectivityBanner {
                ConnectivityBannerView(
                    message: connectivityMessage,
                    isWarning: connectivityBannerIsWarning,
                    accent: selectedAccentTheme.color
                )
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.96),
                    Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.85),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var categorySegmentedBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categoryTabs) { tab in
                        let isSelected = tab.key == selectedCategory
                        Button(action: { selectCategory(tab.key) }) {
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(selectedAccentTheme.color.opacity(0.25))
                                        .matchedGeometryEffect(id: "category-tab", in: categoryTabNamespace)
                                }

                                Text(tab.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? selectedAccentTheme.color : .white.opacity(0.75))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                        }
                        .buttonStyle(.plain)
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, 4)
            }
            .accessibilityIdentifier("content.categoryTabs")
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
            Label(title, systemImage: "checkmark")
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
            Color.black.ignoresSafeArea()

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

            sideActionRail(for: content.quote)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 16)
                .padding(.bottom, max(safeAreaInsets.bottom + 24, 32))
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
                    colors: [Color.black, Color(red: 0.04, green: 0.06, blue: 0.1), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                RoundedRectangle(cornerRadius: quoteLayout.isCompact ? 16 : 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: quoteLayout.isCompact ? 16 : 18, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .frame(width: quoteLayout.width, height: quoteCardHeight)
                    .position(x: imageRect.midX, y: imageRect.midY)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.9))
                    .scaleEffect(1.08)
            }
        }
    }

    private var selectedCategoryTitle: String {
        guard let selectedCategory else { return "Random" }
        return categories.first(where: { $0.key == selectedCategory })?.displayName
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

                if !isDragging {
                    isDragging = true
                    gestureStartOffset = scrollOffset
                    reduceVisualEffectsForInteraction()
                }

                scrollOffset = gestureStartOffset + value.translation.height
            }
            .onEnded { value in
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
                            title: "Top of the feed",
                            message: "You are already at the top of the feed. Try scrolling down."
                        )
                    } else if let maxDepth, proposedDepth > maxDepth {
                        presentAlert(
                            title: "End of this section",
                            message: "Sorry, there is nothing more to show. You reached the bottom of this section. Try changing the tabs/section."
                        )
                    }
                } else if indexShift == 0 {
                    if activeDepth == 0, value.translation.height > 24 {
                        presentAlert(
                            title: "Top of the feed",
                            message: "You are already at the top of the feed. Try scrolling down."
                        )
                    } else if let maxDepth, activeDepth == maxDepth, value.translation.height < -24 {
                        presentAlert(
                            title: "End of this section",
                            message: "Sorry, there is nothing more to show. You reached the bottom of this section. Try changing the tabs/section."
                        )
                    }
                }

                targetDepth = clamped
                snapToDepth(targetDepth)
            }
    }

    private func project(_ velocity: CGFloat) -> CGFloat {
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

    private func wallpaperRect(in container: CGSize) -> CGRect {
        wallpaperRect(in: container, ratio: selectedRatio)
    }

    private func wallpaperRect(in container: CGSize, ratio: WallpaperAspectRatio) -> CGRect {
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

    private func sideActionRail(for quote: Quote?) -> some View {
        VStack(spacing: 14) {
            Menu {
                ForEach(WallpaperAspectRatio.allCases) { ratio in
                    Button(action: { selectRatio(ratio) }) {
                        if ratio == selectedRatio {
                            Label(ratio.rawValue, systemImage: "checkmark")
                        } else {
                            Text(ratio.rawValue)
                        }
                    }
                }
            } label: {
                SideActionIconView(
                    systemName: "crop",
                    label: selectedRatio.rawValue,
                    tint: .white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("content.ratioButton")

            Button(action: {
                guard let quote else { return }
                toggleFavorite(for: quote)
            }) {
                SideActionIconView(
                    systemName: quote.map { quoteVM.isFavorited($0.id) ? "heart.fill" : "heart" } ?? "heart",
                    label: quote.map { quoteVM.isFavorited($0.id) ? "Saved" : "Save" } ?? "Save",
                    tint: quote.map { quoteVM.isFavorited($0.id) ? .red : .white } ?? .white
                )
            }
            .disabled(quote == nil)
            .buttonStyle(.plain)
            .accessibilityIdentifier("content.saveButton")

            Button(action: { showShareSheet = true }) {
                SideActionIconView(
                    systemName: "paperplane.fill",
                    label: "Share",
                    tint: .white
                )
            }
            .disabled(pageVM.current == nil)
            .buttonStyle(.plain)
            .accessibilityIdentifier("content.shareButton")
        }
    }

    private func toggleFavorite(for quote: Quote) {
        if quoteVM.isFavorited(quote.id) {
            quoteVM.removeFromFavorites(quote.id ?? "")
            return
        }

        guard let content = pageVM.current else {
            pageVM.refreshError = "Image is still preparing. Please tap Save again."
            return
        }

        Task {
            let masterImage = LightImageCache.shared.image(for: content.imageURL) ?? content.originalImage
            let localImageData = await jpegDataForStorage(from: masterImage)
            let requestSize = pageVM.imageRequestSize(for: selectedRatio)
            await MainActor.run {
                let resolvedData = localImageData ?? (isUITestMode ? fallbackImageDataForUITest() : nil)
                guard let resolvedData, !resolvedData.isEmpty else {
                    pageVM.refreshError = "Image is still preparing. Please tap Save again."
                    return
                }
                quoteVM.addToFavorites(
                    quote,
                    imageURL: content.imageURL,
                    localImageData: resolvedData,
                    ratioRawValue: selectedRatio.rawValue,
                    imageWidth: requestSize.width,
                    imageHeight: requestSize.height
                )
            }
        }
    }

    private var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestMode")
    }

    private func fallbackImageDataForUITest() -> Data? {
        let size = CGSize(width: 300, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let colors = [UIColor(red: 0.12, green: 0.16, blue: 0.25, alpha: 1).cgColor,
                          UIColor(red: 0.20, green: 0.32, blue: 0.44, alpha: 1).cgColor]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) else {
                UIColor.black.setFill()
                context.cgContext.fill(rect)
                return
            }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
        return image.jpegData(compressionQuality: 0.88)
    }

    private func jpegDataForStorage(from image: UIImage) async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: image.jpegData(compressionQuality: 0.88))
            }
        }
    }

    private func selectAccentTheme(_ theme: AccentTheme) {
        accentThemeRawValue = theme.rawValue
    }

    private func selectCategory(_ key: CategoryKey?) {
        selectedCategory = key
        let lane = laneKey(category: key, ratio: selectedRatio)
        activeDepth = clampedDepth(depthByLane[lane] ?? 0, for: key)
        targetDepth = activeDepth
        currentDepth = activeDepth
        depthByLane[lane] = activeDepth
        scrollOffset = 0
        let hasCachedTarget = cachedContent(category: key, depth: activeDepth, ratio: selectedRatio) != nil
        loadCurrentCoordinate(forceFetch: !hasCachedTarget)
    }

    private func updateConnectivityBanner(isConnected: Bool, animated: Bool) {
        bannerHideTask?.cancel()

        let applyState = {
            if isConnected {
                connectivityBannerIsWarning = false
                connectivityMessage = "Connected"
                showConnectivityBanner = true
            } else {
                connectivityBannerIsWarning = true
                connectivityMessage = "No internet"
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
        let currentContent = pageCache[previousCoord] ?? pageVM.current

        selectedRatio = ratio
        scrollOffset = 0
        reduceVisualEffectsForInteraction()

        let nextLane = laneKey(category: selectedCategory, ratio: ratio)
        let nextDepth = clampedDepth(currentDepth, for: selectedCategory)
        currentDepth = nextDepth
        activeDepth = nextDepth
        depthByLane[nextLane] = nextDepth
        let nextCoord = FeedCoordinate(lane: nextLane, depth: nextDepth)
        if let currentContent {
            let adaptedContent = adaptContent(currentContent, for: ratio)
            pageCache[nextCoord] = adaptedContent
            pageVM.applyCached(adaptedContent)
        }

        adaptCachedPages(for: ratio)
        pruneRenderWindow()
        scheduleVisualEffectsRestore()
    }

    private func minimumQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? 160 : 220
    }

    private func preferredQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? 248 : 320
    }

    private func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let availableHeight = max(imageRect.height - 12, 1)
        let minimumHeight = minimumQuoteCardHeight(for: imageRect)
        let preferredHeight = preferredQuoteCardHeight(for: imageRect)
        return min(preferredHeight, max(availableHeight, minimumHeight))
    }

    private func laneKey(category: CategoryKey?, ratio: WallpaperAspectRatio) -> FeedLaneKey {
        let requestSize = pageVM.imageRequestSize(for: ratio)
        return FeedLaneKey(
            categoryRawValue: category?.rawValue ?? "random",
            ratioRawValue: ratio.rawValue,
            imageWidth: requestSize.width,
            imageHeight: requestSize.height
        )
    }

    private func coordinate(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) -> FeedCoordinate {
        FeedCoordinate(
            lane: laneKey(category: category, ratio: ratio),
            depth: max(depth, 0)
        )
    }

    private func categoryFromRaw(_ rawValue: String) -> CategoryKey? {
        rawValue == "random" ? nil : CategoryKey(rawValue: rawValue)
    }

    private func loadCurrentCoordinate(
        forceFetch: Bool,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil
    ) {
        navigateTo(
            category: selectedCategory,
            depth: currentDepth,
            ratio: selectedRatio,
            forceFetch: forceFetch,
            quoteOverride: quoteOverride,
            minimumLoaderDuration: minimumLoaderDuration
        )
    }

    private func navigateTo(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        forceFetch: Bool,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil
    ) {
        let target = coordinate(category: category, depth: depth, ratio: ratio)

        if !forceFetch, let cached = pageCache[target] {
            currentDepth = depth
            depthByLane[target.lane] = depth
            recordVisitedDepth(depth, lane: target.lane)
            let adapted = adaptContent(cached, for: ratio)
            pageCache[target] = adapted
            pageVM.applyCached(adapted)
            prewarmWindow(around: category, depth: depth, ratio: ratio)
            pruneRenderWindow()
            return
        }

        fetchCoordinate(
            category: category,
            depth: depth,
            ratio: ratio,
            coordinate: target,
            quoteOverride: quoteOverride,
            minimumLoaderDuration: minimumLoaderDuration
        )
    }

    private func fetchCoordinate(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        coordinate: FeedCoordinate,
        quoteOverride: Quote?,
        minimumLoaderDuration: TimeInterval?
    ) {
        guard networkMonitor.isConnected else {
            pageVM.refreshError = "No internet connection. Please reconnect to load new inspiration."
            scheduleVisualEffectsRestore()
            return
        }

        if activeFetchTasks[coordinate] != nil {
            return
        }

        let task = Task {
            defer {
                Task { @MainActor in
                    activeFetchTasks.removeValue(forKey: coordinate)
                }
            }
            do {
                let content = try await pageVM.loadForCurrentPage(
                    category: category,
                    aspectRatio: ratio,
                    quoteOverride: quoteOverride,
                    minimumLoaderDuration: minimumLoaderDuration,
                    cacheIdentity: coordinateIdentity(coordinate)
                )
                if Task.isCancelled { return }

                await MainActor.run {
                    pageCache[coordinate] = content
                    depthByLane[coordinate.lane] = depth
                    ratioQuoteOverrides.removeValue(forKey: coordinate)
                    recordVisitedDepth(depth, lane: coordinate.lane)

                    if isCurrentCoordinate(coordinate) {
                        pageVM.applyCached(content)
                    }
                    prewarmWindow(around: category, depth: depth, ratio: ratio)
                    pruneRenderWindow()
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    scheduleVisualEffectsRestore()
                }
            }
        }
        activeFetchTasks[coordinate] = task
    }

    private func cachedContent(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent? {
        let key = coordinate(category: category, depth: depth, ratio: ratio)
        guard let cached = pageCache[key] else { return nil }
        return adaptContent(cached, for: ratio)
    }

    private func isCurrentCoordinate(_ value: FeedCoordinate) -> Bool {
        value == coordinate(category: selectedCategory, depth: currentDepth, ratio: selectedRatio)
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
        guard networkMonitor.isConnected else { return }

        // Keep prewarm narrowly focused around the current lane to reduce CPU/network contention.
        for prewarmDepth in surroundingDepths(around: depth, radius: prewarmDepthRadius) {
            prewarmCell(category: category, depth: prewarmDepth, ratio: ratio)
        }

        for prewarmCategory in surroundingCategories(around: category, radius: horizontalRenderRadius)
            where prewarmCategory != category {
            let alignedDepth = clampedDepth(depth, for: prewarmCategory)
            prewarmCell(category: prewarmCategory, depth: alignedDepth, ratio: ratio)
        }
    }

    private func surroundingCategories(around center: CategoryKey?, radius: Int) -> [CategoryKey?] {
        let allCategories: [CategoryKey?] = [nil] + categories.map(\.key)
        guard let centerIndex = allCategories.firstIndex(where: { $0 == center }) else {
            return [center]
        }

        var selected: [CategoryKey?] = []
        for offset in (-radius)...radius {
            var index = centerIndex + offset
            while index < 0 {
                index += allCategories.count
            }
            while index >= allCategories.count {
                index -= allCategories.count
            }
            let category = allCategories[index]
            if !selected.contains(where: { $0 == category }) {
                selected.append(category)
            }
        }
        return selected
    }

    private func surroundingDepths(around center: Int, radius: Int) -> [Int] {
        var values: [Int] = []
        for offset in (-radius)...radius {
            let value = center + offset
            if value >= 0 {
                values.append(value)
            }
        }
        return values
    }

    private func prewarmCell(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) {
        let target = coordinate(category: category, depth: depth, ratio: ratio)
        let targetIdentity = coordinateIdentity(target)
        guard pageCache[target] == nil else { return }
        guard !prewarmInFlight.contains(target) else { return }
        guard activeFetchTasks[target] == nil else { return }
        guard prewarmInFlight.count < maxPrewarmInFlightCount else { return }

        prewarmInFlight.insert(target)
        Task {
            defer {
                Task { @MainActor in
                    prewarmInFlight.remove(target)
                }
            }

            do {
                let content = try await pageVM.prefetch(
                    category: category,
                    aspectRatio: ratio,
                    quoteOverride: await MainActor.run { ratioQuoteOverrides[target] },
                    cacheIdentity: targetIdentity
                )
                if Task.isCancelled { return }

                await MainActor.run {
                    pageCache[target] = content
                    ratioQuoteOverrides.removeValue(forKey: target)
                    pruneRenderWindow()
                }
            } catch {
                // Ignore prewarm failures to keep feed responsive.
            }
        }
    }

    private func pruneRenderWindow() {
        let keepCategories = Set(
            surroundingCategories(around: selectedCategory, radius: horizontalRenderRadius)
                .map { $0?.rawValue ?? "random" }
        )
        let keepDepths = Set(surroundingDepths(around: currentDepth, radius: verticalRenderRadius))
        let requestSize = pageVM.imageRequestSize(for: selectedRatio)
        let currentLane = laneKey(category: selectedCategory, ratio: selectedRatio)
        let visitedDepths = Set(visitedDepthsByLane[currentLane] ?? [])

        pageCache = pageCache.filter { key, _ in
            if key.lane == currentLane {
                return visitedDepths.contains(key.depth) || keepDepths.contains(key.depth)
            }
            return key.lane.ratioRawValue == selectedRatio.rawValue
                && key.lane.imageWidth == requestSize.width
                && key.lane.imageHeight == requestSize.height
                && keepCategories.contains(key.lane.categoryRawValue)
                && keepDepths.contains(key.depth)
        }

        ratioQuoteOverrides = ratioQuoteOverrides.filter { key, _ in
            key.lane.ratioRawValue == selectedRatio.rawValue
                && key.lane.imageWidth == requestSize.width
                && key.lane.imageHeight == requestSize.height
                && keepCategories.contains(key.lane.categoryRawValue)
                && keepDepths.contains(key.depth)
        }
    }

    private func clearLaneCache(category: CategoryKey?, ratio: WallpaperAspectRatio) {
        let lane = laneKey(category: category, ratio: ratio)
        pageCache = pageCache.filter { $0.key.lane != lane }
        depthByLane[lane] = 0
        visitedDepthsByLane[lane] = []
    }

    private func recordVisitedDepth(_ depth: Int, lane: FeedLaneKey) {
        var depths = visitedDepthsByLane[lane] ?? []
        if let existingIndex = depths.firstIndex(of: depth) {
            depths.remove(at: existingIndex)
        }
        depths.append(depth)
        if depths.count > visitedDepthLimit {
            depths.removeFirst(depths.count - visitedDepthLimit)
        }
        visitedDepthsByLane[lane] = depths
    }

    private func coordinateIdentity(_ coordinate: FeedCoordinate) -> String {
        "\(coordinate.lane.categoryRawValue)|\(coordinate.lane.ratioRawValue)|\(coordinate.lane.imageWidth)x\(coordinate.lane.imageHeight)|d\(coordinate.depth)"
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
            depthByLane[laneKey(category: selectedCategory, ratio: selectedRatio)] = clamped
        }
    }

    private func categoryTitle(for category: Category) -> String {
        guard let quoteCount = category.quoteCount else {
            return category.displayName
        }
        return "\(category.displayName) (\(quoteCount))"
    }

    private var randomTabTitle: String {
        if let randomQuoteCount {
            return "Random (\(randomQuoteCount))"
        }
        return "Random"
    }

    private func maxDepth(for category: CategoryKey?) -> Int? {
        guard let category else { return nil }
        guard let quoteCount = categories.first(where: { $0.key == category })?.quoteCount, quoteCount > 0 else {
            return nil
        }
        return max(quoteCount - 1, 0)
    }

    private func clampedDepth(_ depth: Int, for category: CategoryKey?) -> Int {
        let nonNegativeDepth = max(depth, 0)
        guard let maxDepth = maxDepth(for: category) else { return nonNegativeDepth }
        return min(nonNegativeDepth, maxDepth)
    }

    private func presentAlert(title: String, message: String) {
        activeAlert = FeedAlert(title: title, message: message)
    }

    private func shareLayoutSize() -> CGSize {
        let requestSize = pageVM.imageRequestSize(for: selectedRatio)
        let scale = max(UIScreen.main.scale, 1)
        return CGSize(
            width: CGFloat(requestSize.width) / scale,
            height: CGFloat(requestSize.height) / scale
        )
    }

    private func adaptContent(
        _ content: FeedPageViewModel.FeedPageContent,
        for ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent {
        let sourceImage = LightImageCache.shared.image(for: content.imageURL) ?? content.originalImage
        guard let targetAspect = ratio.value else {
            return FeedPageViewModel.FeedPageContent(
                quote: content.quote,
                image: sourceImage,
                originalImage: sourceImage,
                imageURL: content.imageURL,
                imageSource: content.imageSource,
                seed: content.seed,
                imageCategoryTitle: content.imageCategoryTitle
            )
        }
        let croppedImage = cropImage(sourceImage, toAspect: targetAspect)
        return FeedPageViewModel.FeedPageContent(
            quote: content.quote,
            image: croppedImage,
            originalImage: sourceImage,
            imageURL: content.imageURL,
            imageSource: content.imageSource,
            seed: content.seed,
            imageCategoryTitle: content.imageCategoryTitle
        )
    }

    private func adaptCachedPages(for ratio: WallpaperAspectRatio) {
        pageCache = pageCache.mapValues { content in
            adaptContent(content, for: ratio)
        }
    }

    private func cropImage(_ image: UIImage, toAspect aspect: CGFloat) -> UIImage {
        guard aspect > 0 else { return image }
        let normalized = normalizedImage(image)
        guard let cgImage = normalized.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 0, height > 0 else { return normalized }

        let currentAspect = width / height
        if abs(currentAspect - aspect) < 0.001 {
            return normalized
        }

        let cropRect: CGRect
        if currentAspect > aspect {
            let newWidth = height * aspect
            cropRect = CGRect(x: (width - newWidth) / 2.0, y: 0, width: newWidth, height: height)
        } else {
            let newHeight = width / aspect
            cropRect = CGRect(x: 0, y: (height - newHeight) / 2.0, width: width, height: newHeight)
        }

        guard let cropped = cgImage.cropping(to: cropRect.integral) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    private func normalizedImage(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

#Preview {
    let container = AppContainer.live
    HomeView(
        quoteVM: container.makeQuoteViewModel(),
        pageVM: container.makeFeedPageViewModel()
    )
}
