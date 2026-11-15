import SwiftUI
import UIKit

extension FavoriteCellView {
    func renderImageIfNeeded() {
        loadTask?.cancel()
        guard renderedImage == nil else { return }

        if let localURL = favorite.resolvedLocalImageURL,
           let localImage = UIImage(contentsOfFile: localURL.path) {
            renderedImage = localImage; isLoading = false
            return
        }

        guard let url = imageURL else { isLoading = false; return }

        isLoading = true
        loadTask = Task {
            let cached = await imageLoader.cachedImage(for: url)
            if Task.isCancelled { return }
            await MainActor.run {
                if let cached {
                    renderedImage = cached
                    persistImageIfNeeded(from: cached)
                }
                isLoading = false
            }
        }
    }

    private func persistImageIfNeeded(from image: UIImage) {
        guard favorite.localImagePath?.isEmpty ?? true else { return }
        let callback = onImageDataResolved
        DispatchQueue.global(qos: .utility).async {
            guard let imageData = image.jpegData(compressionQuality: 0.88) else { return }
            DispatchQueue.main.async { callback?(imageData) }
        }
    }
}
