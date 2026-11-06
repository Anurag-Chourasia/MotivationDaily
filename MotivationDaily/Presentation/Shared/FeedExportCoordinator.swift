import UIKit
import DesignTokensKit

final class FeedExportCoordinator {
    var isUITestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestMode")
    }

    func prepareFavoriteImageData(
        for content: FeedPageViewModel.FeedPageContent,
        imageLoader: any ImageLoading
    ) async -> Data? {
        let masterImage = await imageLoader.cachedImage(for: content.imageURL) ?? content.originalImage
        let compressedData = await jpegDataForStorage(from: masterImage)
        if let compressedData, !compressedData.isEmpty {
            return compressedData
        }
        return isUITestMode ? fallbackImageDataForUITest() : nil
    }

    func jpegDataForStorage(from image: UIImage) async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: image.jpegData(compressionQuality: 0.88))
            }
        }
    }

    func fallbackImageDataForUITest() -> Data? {
        let size = CGSize(width: 300, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let colors = [
                PlaceholderColorToken.uiGradientStart.cgColor,
                PlaceholderColorToken.uiGradientEnd.cgColor
            ]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) else {
                context.cgContext.setFillColor(PlaceholderColorToken.uiGradientStart.cgColor)
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

    func shareLayoutSize(
        for ratio: WallpaperAspectRatio,
        using pageVM: FeedPageViewModel
    ) -> CGSize {
        let requestSize = pageVM.imageRequestSize(for: ratio)
        let scale = max(UIScreen.main.scale, 1)
        return CGSize(
            width: CGFloat(requestSize.width) / scale,
            height: CGFloat(requestSize.height) / scale
        )
    }
}
