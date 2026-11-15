import SwiftUI
import UIKit

extension FullScreenImageView {
    func resolveDisplayedImage() {
        loadTask?.cancel()
        displayedImage = nil

        if let favoriteImage {
            displayedImage = favoriteImage
            persistImageIfNeeded(favoriteImage)
            return
        }

        if let localURL = favorite?.resolvedLocalImageURL,
           let localImage = UIImage(contentsOfFile: localURL.path) {
            displayedImage = localImage
            return
        }

        guard let url = favorite?.imageURL else {
            isLoadingImage = false
            return
        }

        isLoadingImage = true
        loadTask = Task {
            let cached = await imageLoader.cachedImage(for: url)
            if Task.isCancelled { return }
            await MainActor.run {
                if let cached {
                    displayedImage = cached
                    persistImageIfNeeded(cached)
                }
                isLoadingImage = false
            }
        }
    }

    private func persistImageIfNeeded(_ image: UIImage) {
        guard let favorite else { return }
        if let localPath = favorite.localImagePath, !localPath.isEmpty { return }
        let favoriteID = favorite.id
        let callback = onImageDataResolved
        DispatchQueue.global(qos: .utility).async {
            guard let imageData = image.jpegData(compressionQuality: 0.88) else { return }
            DispatchQueue.main.async { callback?(favoriteID, imageData) }
        }
    }

    func initialRatio() -> WallpaperAspectRatio {
        guard let raw = favorite?.ratioRawValue else { return .fullScreen }
        return WallpaperAspectRatio.allCases.first(where: { $0.rawValue == raw }) ?? .fullScreen
    }
}
