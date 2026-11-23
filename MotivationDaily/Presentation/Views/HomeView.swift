import SwiftUI
import AuthKit
import DesignTokensKit
import LocalizationKit

struct HomeView: View {
    @AppStorage(AccentTheme.storageKey) var accentThemeRawValue = AccentTheme.default.rawValue
    @StateObject var quoteVM: QuoteViewModel
    @StateObject var pageVM: FeedPageViewModel
    @StateObject var networkMonitor = NetworkMonitor()
    @StateObject var cacheCoordinator = FeedCacheCoordinator()
    let exportCoordinator = FeedExportCoordinator()

    @State var showFavorites = false
    @State var showShareSheet = false
    @State var showAboutDeveloper = false
    @State var showUserSettings = false
    @State var showDeleteAccountConfirmation = false
    @State var sharingContent: FeedPageViewModel.FeedPageContent?
    @State var selectedCategory: CategoryKey?
    @State var selectedRatio: WallpaperAspectRatio = .fullScreen
    @State var categories: [Category] = []

    @State var scrollOffset: CGFloat = .zero; @State var gestureStartOffset: CGFloat = .zero
    @State var activeDepth: Int = 0; @State var targetDepth: Int = 0
    @State var isDragging: Bool = false; @State var isHorizontallyDragging: Bool = false
    @State var bootPhase: FeedBootPhase = .cold; @State var currentDepth: Int = 0
    @State var containerSize: CGSize = .zero

    @State var initialBootHasRun = false
    @State var hasShownInitialConnectivityBanner = false
    @State var showConnectivityBanner = false
    @State var connectivityBannerIsWarning = false
    @State var connectivityMessage = ""
    @State var bannerHideTask: DispatchWorkItem?
    @State var activeAlert: FeedAlert?
    @State var randomQuoteCount: Int?
    @State var visualEffectsReduced = false
    @State var visualEffectsRestoreTask: DispatchWorkItem?
    @Namespace var categoryTabNamespace

    let effectsRestoreDelay: TimeInterval = 0.08
    let actionRailExclusionWidth: CGFloat = DesignMetric.p140
    let actionRailExclusionHeight: CGFloat = DesignMetric.p400
    let imageLoader: any ImageLoading
    let user: AuthUser?
    let sessionManager: SessionManager?

    var selectedAccentTheme: AccentTheme { AccentTheme.resolve(from: accentThemeRawValue) }

    init(
        quoteVM: QuoteViewModel, pageVM: FeedPageViewModel,
        imageLoader: (any ImageLoading)? = nil,
        user: AuthUser? = nil, sessionManager: SessionManager? = nil
    ) {
        _quoteVM = StateObject(wrappedValue: quoteVM); _pageVM = StateObject(wrappedValue: pageVM)
        self.imageLoader = imageLoader ?? pageVM.imageLoader
        self.user = user; self.sessionManager = sessionManager
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle().fill(\.black).ignoresSafeArea()
                if bootPhase != .cold {
                    feedContainer.gesture(feedSwipeGesture).simultaneousGesture(horizontalSwipeGesture)
                }
            }
            .onAppear { containerSize = proxy.size }
            .onChange(of: proxy.size) { containerSize = $0 }
        }
        .background(\.black, ignoresSafeAreaEdges: .all)
        .task { await performInitialBootIfNeeded() }
        .fullScreenCover(isPresented: $showFavorites) { FavoritesView(quoteVM: quoteVM, imageLoader: imageLoader) }
        .sheet(isPresented: $showShareSheet, onDismiss: { sharingContent = nil }) { shareSheetContent }
        .sheet(isPresented: $showUserSettings) { userSettingsSheetContent }
        .fullScreenCover(isPresented: $showAboutDeveloper) { AboutView() }
        .alert(item: $activeAlert) {
            Alert(title: Text($0.title), message: Text($0.message), dismissButton: .default(\.ok) { activeAlert = nil })
        }
        .confirmationDialog(
            \CommonStrings.accountDeleteConfirmationTitle,
            isPresented: $showDeleteAccountConfirmation, titleVisibility: .visible
        ) { deleteAccountButtons } message: { Text(\CommonStrings.accountDeleteConfirmationMessage) }
        .onChange(of: pageVM.refreshError) { msg in
            guard let msg else { return }
            presentAlert(title: String(\MotivationStrings.refreshFailed), message: msg)
            pageVM.refreshError = nil
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            guard hasShownInitialConnectivityBanner || bootPhase != .cold else { return }
            updateConnectivityBanner(isConnected: isConnected, animated: true)
        }
        .onChange(of: activeDepth) { prewarmWindow(around: selectedCategory, depth: $0, ratio: selectedRatio) }
        .onDisappear { cleanupTasks() }
        .safeAreaInset(edge: .top) {
            if bootPhase != .cold { topChromeView.transition(.opacity) }
        }
    }
}
