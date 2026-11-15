import SwiftUI
import DesignTokensKit
import LocalizationKit

extension HomeView {
    func toggleFavorite(for content: FeedPageViewModel.FeedPageContent) {
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

    func selectRatio(_ ratio: WallpaperAspectRatio) {
        guard selectedRatio != ratio else { return }
        let prevCoord = coordinate(category: selectedCategory, depth: currentDepth, ratio: selectedRatio)
        let currentContent = cacheCoordinator.pageCache[prevCoord] ?? pageVM.current
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
            let adapted = cacheCoordinator.adaptContent(currentContent, for: ratio)
            cacheCoordinator.pageCache[nextCoord] = adapted
            pageVM.applyCached(adapted)
        }
        cacheCoordinator.adaptCachedPages(for: ratio)
        cacheCoordinator.pruneRenderWindow(
            selectedCategory: selectedCategory, selectedRatio: selectedRatio,
            currentDepth: currentDepth, categories: categories, pageVM: pageVM
        )
        scheduleVisualEffectsRestore()
    }

    func updateConnectivityBanner(isConnected: Bool, animated: Bool) {
        bannerHideTask?.cancel()
        let applyState: () -> Void = {
            connectivityBannerIsWarning = !isConnected
            connectivityMessage = isConnected
                ? String(\MotivationStrings.connectivityConnected)
                : String(\MotivationStrings.connectivityOffline)
            showConnectivityBanner = true
        }
        if animated { withAnimation(.easeInOut(duration: 0.25)) { applyState() } }
        else { applyState() }
        guard isConnected else { return }
        let hideTask = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) { showConnectivityBanner = false }
        }
        bannerHideTask = hideTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: hideTask)
    }

    func presentAlert(title: String, message: String) {
        activeAlert = FeedAlert(title: title, message: message)
    }

    func selectAccentTheme(_ theme: AccentTheme) { accentThemeRawValue = theme.rawValue }
    func shareContent(_ content: FeedPageViewModel.FeedPageContent) { sharingContent = content; showShareSheet = true }
    func openFavorites() { showFavorites = true }
    func openAbout() { showAboutDeveloper = true }
    func requestDeleteAccount() { showDeleteAccountConfirmation = true }
}
