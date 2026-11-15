import SwiftUI
import DesignTokensKit

extension HomeView {
    func wallpaperRect(in container: CGSize) -> CGRect {
        wallpaperRect(in: container, ratio: selectedRatio)
    }

    func wallpaperRect(in container: CGSize, ratio: WallpaperAspectRatio) -> CGRect {
        HomeLayoutHelper.wallpaperRect(in: container, ratio: ratio)
    }

    func minimumQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? DesignMetric.p160 : DesignMetric.p210
    }

    func preferredQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let layout = QuoteCardLayout.style(for: imageRect)
        return layout.isCompact ? DesignMetric.p248 : DesignMetric.p320
    }

    func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        HomeLayoutHelper.resolvedQuoteCardHeight(for: imageRect)
    }

    func categoryFromRaw(_ rawValue: String) -> CategoryKey? {
        rawValue == "random" ? nil : CategoryKey(rawValue: rawValue)
    }

    func surroundingCategories(around center: CategoryKey?, radius: Int) -> [CategoryKey?] {
        cacheCoordinator.surroundingCategories(around: center, in: categories, radius: radius)
    }

    func surroundingDepths(around center: Int, radius: Int) -> [Int] {
        cacheCoordinator.surroundingDepths(around: center, radius: radius)
    }

    func adaptContent(
        _ content: FeedPageViewModel.FeedPageContent,
        for ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent {
        cacheCoordinator.adaptContent(content, for: ratio)
    }

    func cropImage(_ image: UIImage, toAspect aspect: CGFloat) -> UIImage {
        cacheCoordinator.cropImage(image, toAspect: aspect)
    }

    func normalizedImage(_ image: UIImage) -> UIImage {
        cacheCoordinator.normalizedImage(image)
    }
}
