import SwiftUI
import UIKit

enum QuoteImageComposer {
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
        let layoutCanvas = layoutSize ?? outputCanvas
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
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        let quote = Quote(
            id: nil,
            text: quoteText,
            author: author,
            source: .zenQuotes,
            categoryKey: nil
        )
        let imageRect = CGRect(origin: .zero, size: size)
        let layout = QuoteCardLayout.style(for: imageRect)

        let quoteOnlyView = ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.1),
                    Color.black
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
        .frame(width: size.width, height: size.height)

        return quoteOnlyView.snapshot(size: size, scale: max(scale, 1))
    }

    static func composeQuoteOnlyImage(
        quoteText: String,
        author: String,
        size: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage {
        composeQuoteOnly(
            quoteText: quoteText,
            author: author,
            size: size,
            scale: scale
        )
    }

    static func renderContext(for image: UIImage) -> RenderContext {
        if image.size.width > 0, image.size.height > 0, image.scale > 0 {
            // Preserve the exact source canvas and scale so composed output matches in-app rendering.
            return RenderContext(canvasSize: image.size, scale: image.scale)
        }

        let pixelSize = pixelSize(for: image)
        return RenderContext(
            canvasSize: CGSize(
                width: max(pixelSize.width, 1),
                height: max(pixelSize.height, 1)
            ),
            scale: 1
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
