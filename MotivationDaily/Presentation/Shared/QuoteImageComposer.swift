import SwiftUI
import UIKit
import DesignTokensKit

@MainActor
enum QuoteImageComposer {
    private static let maxCanvasDimension = CGFloat(1920)
    private static let maxPixelDimension = CGFloat(2048)

    struct RenderContext: Equatable {
        let canvasSize: CGSize
        let scale: CGFloat
    }

    static func compose(
        image: UIImage,
        quoteText: String,
        author: String,
        layoutSize: CGSize? = nil
    ) -> UIImage {
        let context = renderContext(for: image)
        let quote = Quote(
            id: nil,
            text: quoteText,
            author: author,
            source: .zenQuotes,
            categoryKey: nil
        )
        let fallbackAspect = context.canvasSize.width / max(context.canvasSize.height, 1)
        let targetAspect = aspectRatio(from: layoutSize) ?? fallbackAspect
        let outputCanvas = canvasForAspect(targetAspect, inside: context.canvasSize)
        let imageRect = CGRect(origin: .zero, size: outputCanvas)
        let layoutCanvas = clampedSize(layoutSize) ?? outputCanvas
        let layoutRect = CGRect(origin: .zero, size: layoutCanvas)
        let layout = QuoteCardLayout.style(for: layoutRect)
        let scaleFactor = min(
            outputCanvas.width / max(layoutCanvas.width, 1),
            outputCanvas.height / max(layoutCanvas.height, 1)
        )

        let composedView = ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: outputCanvas.width, height: outputCanvas.height)
                .clipped()

            QuoteCardView(
                quote: quote,
                dominantColor: nil,
                overlayOpacity: 0.5,
                compactStyle: layout.isCompact,
                showsDepthEffects: true
            )
            .frame(width: layout.width)
            .scaleEffect(scaleFactor)
            .position(x: imageRect.midX, y: imageRect.midY)
        }
        .frame(width: outputCanvas.width, height: outputCanvas.height)

        return composedView.snapshot(size: outputCanvas, scale: context.scale)
    }

    static func composeQuoteImage(
        source: UIImage,
        quoteText: String,
        author: String,
        layoutSize: CGSize? = nil
    ) -> UIImage {
        compose(image: source, quoteText: quoteText, author: author, layoutSize: layoutSize)
    }

    static func composeQuoteOnly(
        quoteText: String,
        author: String,
        size: CGSize,
        scale: CGFloat = min(UIScreen.main.scale, 2.0)
    ) -> UIImage {
        let targetSize = clampedSize(size) ?? size
        let maxScaleFromPixels = maxPixelDimension / max(targetSize.width, targetSize.height)
        let safeScale = min(max(scale, 1.0), min(2.0, maxScaleFromPixels))

        let quote = Quote(
            id: nil,
            text: quoteText,
            author: author,
            source: .zenQuotes,
            categoryKey: nil
        )
        let imageRect = CGRect(origin: .zero, size: targetSize)
        let layout = QuoteCardLayout.style(for: imageRect)

        let quoteOnlyView = ZStack {
            LinearGradient(
                themeColors: [
                    \.black,
                    \.ink,
                    \.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            QuoteCardView(
                quote: quote,
                dominantColor: nil,
                overlayOpacity: 0.5,
                compactStyle: layout.isCompact,
                showsDepthEffects: true
            )
            .frame(width: layout.width)
            .position(x: imageRect.midX, y: imageRect.midY)
        }
        .frame(width: targetSize.width, height: targetSize.height)

        return quoteOnlyView.snapshot(size: targetSize, scale: safeScale)
    }

    static func composeQuoteOnlyImage(
        quoteText: String,
        author: String,
        size: CGSize,
        scale: CGFloat = min(UIScreen.main.scale, 2.0)
    ) -> UIImage {
        composeQuoteOnly(
            quoteText: quoteText,
            author: author,
            size: size,
            scale: scale
        )
    }

    static func renderContext(for image: UIImage) -> RenderContext {
        let rawWidth: CGFloat
        let rawHeight: CGFloat

        if image.size.width > 0, image.size.height > 0 {
            rawWidth = image.size.width
            rawHeight = image.size.height
        } else {
            let pixelSize = pixelSize(for: image)
            rawWidth = max(pixelSize.width, 1)
            rawHeight = max(pixelSize.height, 1)
        }

        let largestSide = max(rawWidth, rawHeight)
        let downscale = largestSide > maxCanvasDimension ? (maxCanvasDimension / largestSide) : 1.0
        let clampedCanvas = CGSize(
            width: max(round(rawWidth * downscale), 1),
            height: max(round(rawHeight * downscale), 1)
        )
        let maxScaleFromPixels = maxPixelDimension / max(clampedCanvas.width, clampedCanvas.height)
        let scale = min(max(image.scale, 1.0), min(2.0, maxScaleFromPixels))

        return RenderContext(canvasSize: clampedCanvas, scale: scale)
    }

    private static func clampedSize(_ size: CGSize?) -> CGSize? {
        guard let size, size.width > 0, size.height > 0 else { return nil }
        let largest = max(size.width, size.height)
        guard largest > maxCanvasDimension else { return size }
        let factor = maxCanvasDimension / largest
        return CGSize(
            width: max(round(size.width * factor), 1),
            height: max(round(size.height * factor), 1)
        )
    }

    private static func pixelSize(for image: UIImage) -> CGSize {
        if let cgImage = image.cgImage {
            return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        }

        let scale = max(image.scale, 1)
        return CGSize(
            width: max(image.size.width * scale, 1),
            height: max(image.size.height * scale, 1)
        )
    }

    private static func aspectRatio(from size: CGSize?) -> CGFloat? {
        guard let size, size.width > 0, size.height > 0 else {
            return nil
        }
        return size.width / size.height
    }

    private static func canvasForAspect(_ aspect: CGFloat, inside source: CGSize) -> CGSize {
        let targetAspect = max(aspect, 0.01)
        let sourceWidth = max(source.width, 1)
        let sourceHeight = max(source.height, 1)
        let sourceAspect = sourceWidth / sourceHeight

        if sourceAspect > targetAspect {
            let width = sourceHeight * targetAspect
            return CGSize(width: max(width, 1), height: sourceHeight)
        } else {
            let height = sourceWidth / targetAspect
            return CGSize(width: sourceWidth, height: max(height, 1))
        }
    }
}
