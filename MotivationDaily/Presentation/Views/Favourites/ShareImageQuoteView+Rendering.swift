import SwiftUI
import UIKit

extension ShareImageQuoteView {
    func createShareableImage() async {
        imageLoadTask?.cancel()
        let screenSize = UIScreen.main.bounds.size
        let quoteOnlySize = preferredLayoutSize() ?? screenSize
        sourceImage = nil
        compositeImage = nil
        quoteOnlyImage = nil
        isPreparingImage = true

        await Task.yield()
        if Task.isCancelled { return }

        renderQuoteOnly(size: quoteOnlySize)

        if let favorite {
            if let favoriteImage {
                sourceImage = favoriteImage
                renderComposite(image: favoriteImage, content: quoteText, author: quoteAuthor)
                isPreparingImage = false
                return
            }

            if let localURL = favorite.resolvedLocalImageURL,
               let localImage = UIImage(contentsOfFile: localURL.path) {
                sourceImage = localImage
                renderComposite(image: localImage, content: quoteText, author: quoteAuthor)
                isPreparingImage = false
                return
            }

            if let imageURL = favorite.imageURL {
                isPreparingImage = true
                let cached = await imageLoader.cachedImage(for: imageURL)
                if Task.isCancelled { return }
                if let cached {
                    sourceImage = cached
                    renderComposite(image: cached, content: quoteText, author: quoteAuthor)
                }
                isPreparingImage = false
                return
            }
        }

        if let wallpaper {
            sourceImage = wallpaper
            renderComposite(image: wallpaper, content: quoteText, author: quoteAuthor)
            isPreparingImage = false
            return
        }

        isPreparingImage = false
    }

    private func renderComposite(image: UIImage, content: String, author: String) {
        compositeImage = composeQuoteImageWithRetry(
            source: image, content: content, author: author, layoutSize: resolvedLayoutSize(for: image)
        )
    }

    private func renderQuoteOnly(size: CGSize) {
        quoteOnlyImage = composeQuoteOnlyWithRetry(size: size)
    }

    private func composeQuoteImageWithRetry(
        source: UIImage, content: String, author: String, layoutSize: CGSize?
    ) -> UIImage? {
        let first = QuoteImageComposer.composeQuoteImage(
            source: source, quoteText: content, author: author, layoutSize: layoutSize
        )
        if !isLikelyBlank(first) { return first }

        let second = QuoteImageComposer.composeQuoteImage(
            source: source, quoteText: content, author: author, layoutSize: layoutSize
        )
        if !isLikelyBlank(second) { return second }

        presentSnapshotFailureAlert()
        return nil
    }

    private func composeQuoteOnlyWithRetry(size: CGSize) -> UIImage? {
        let first = QuoteImageComposer.composeQuoteOnlyImage(
            quoteText: quoteText, author: quoteAuthor, size: size
        )
        if !isLikelyBlank(first) { return first }

        let second = QuoteImageComposer.composeQuoteOnlyImage(
            quoteText: quoteText, author: quoteAuthor, size: size
        )
        if !isLikelyBlank(second) { return second }

        presentSnapshotFailureAlert()
        return nil
    }
}
