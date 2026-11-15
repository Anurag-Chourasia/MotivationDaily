import SwiftUI

extension HomeView {
    @MainActor
    func performInitialBootIfNeeded() async {
        guard !initialBootHasRun else { return }
        initialBootHasRun = true
        pageVM.warmupCatalogue()
        await loadCategoriesIfNeeded()
        withAnimation(.easeOut(duration: 0.2)) { bootPhase = .preparing }
        if !hasShownInitialConnectivityBanner {
            hasShownInitialConnectivityBanner = true
            updateConnectivityBanner(isConnected: networkMonitor.isConnected, animated: false)
        }
        activeDepth = clampedDepth(currentDepth, for: selectedCategory)
        targetDepth = activeDepth
        currentDepth = activeDepth
        loadCurrentCoordinate(forceFetch: false, minimumLoaderDuration: 0.35)
    }

    func loadCurrentCoordinate(
        forceFetch: Bool,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil
    ) {
        cacheCoordinator.navigateTo(
            category: selectedCategory, depth: currentDepth, ratio: selectedRatio,
            forceFetch: forceFetch, quoteOverride: quoteOverride,
            minimumLoaderDuration: minimumLoaderDuration, pageVM: pageVM,
            isConnected: networkMonitor.isConnected, categories: categories,
            onFailure: { scheduleVisualEffectsRestore() }
        )
    }

    func snapToDepth(_ depth: Int) {
        let pageHeight = UIScreen.main.bounds.height
        let destination = -CGFloat(depth - activeDepth) * pageHeight
        withAnimation(.interpolatingSpring(stiffness: 420, damping: 42)) { scrollOffset = destination }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            activeDepth = depth; currentDepth = depth; scrollOffset = 0
            loadCurrentCoordinate(forceFetch: false)
            prewarmWindow(around: selectedCategory, depth: activeDepth, ratio: selectedRatio)
            scheduleVisualEffectsRestore()
        }
    }

    func isActionRailInteraction(at startLocation: CGPoint) -> Bool {
        let b = UIScreen.main.bounds
        return startLocation.x >= (b.width - actionRailExclusionWidth) &&
               startLocation.y >= (b.height - actionRailExclusionHeight)
    }

    func reduceVisualEffectsForInteraction() {
        visualEffectsRestoreTask?.cancel()
        visualEffectsRestoreTask = nil
        visualEffectsReduced = true
    }

    func scheduleVisualEffectsRestore() {
        visualEffectsRestoreTask?.cancel()
        let task = DispatchWorkItem { visualEffectsReduced = false }
        visualEffectsRestoreTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + effectsRestoreDelay, execute: task)
    }

    func prewarmWindow(around category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) {
        cacheCoordinator.prewarmWindow(
            around: category, depth: depth, ratio: ratio,
            categories: categories, pageVM: pageVM, isConnected: networkMonitor.isConnected
        )
    }

    func prewarmCell(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) {
        cacheCoordinator.prewarmCell(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }

    func maxDepth(for category: CategoryKey?) -> Int? {
        cacheCoordinator.maxDepth(for: category, in: categories)
    }
    func clampedDepth(_ depth: Int, for category: CategoryKey?) -> Int {
        cacheCoordinator.clampedDepth(depth, for: category, in: categories)
    }
    func shareLayoutSize() -> CGSize {
        exportCoordinator.shareLayoutSize(for: selectedRatio, using: pageVM)
    }
    func laneKey(category: CategoryKey?, ratio: WallpaperAspectRatio) -> FeedLaneKey {
        cacheCoordinator.laneKey(category: category, ratio: ratio, pageVM: pageVM)
    }
    func coordinate(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio) -> FeedCoordinate {
        cacheCoordinator.coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }
    func cachedContent(
        category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent? {
        cacheCoordinator.cachedContent(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }
}
