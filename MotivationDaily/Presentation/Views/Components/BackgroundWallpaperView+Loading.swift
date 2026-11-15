import SwiftUI
import UIKit

extension BackgroundWallpaperView {
    func fittedImageFrame(in container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        guard let aspectRatio, aspectRatio > 0 else { return container }
        let width = container.width
        return CGSize(width: width, height: width / aspectRatio)
    }

    func loadImage(from url: URL?) {
        guard displayedURL != url || currentImage == nil else { return }
        if activeURL == url, isLoading { return }
        loadTask?.cancel()
        activeURL = url

        guard let url else {
            currentImage = nil; nextImage = nil; isLoading = false; displayedURL = nil
            return
        }

        isLoading = true
        loadTask = Task {
            if let cached = await imageLoader.cachedImage(for: url) {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard activeURL == url else { return }
                    currentImage = cached; nextImage = nil; isLoading = false
                    displayedURL = url; onImageLoaded?(cached, url)
                }
                return
            }

            do {
                let image = try await imageLoader.load(url: url)
                if Task.isCancelled { return }
                await MainActor.run {
                    guard activeURL == url else { return }
                    nextImage = image; currentImage = nextImage; nextImage = nil
                    isLoading = false; displayedURL = url; onImageLoaded?(image, url)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard activeURL == url else { return }
                    nextImage = nil; isLoading = false; onImageFailed?(url)
                }
            }
        }
    }
}
