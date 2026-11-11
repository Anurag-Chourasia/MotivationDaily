import SwiftUI
import UIKit

@MainActor
extension View {
    func snapshot(size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let clampedScale = min(max(scale, 1.0), 2.0)
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = clampedScale
        renderer.proposedSize = ProposedViewSize(size)
        if let image = renderer.uiImage {
            return image
        }

        let controller = UIHostingController(rootView: self)
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        controller.view.contentScaleFactor = clampedScale
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = clampedScale
        let graphicsRenderer = UIGraphicsImageRenderer(size: size, format: format)
        return graphicsRenderer.image { ctx in
            controller.view.layer.render(in: ctx.cgContext)
        }
    }
}
