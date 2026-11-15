import SwiftUI
import UIKit
import LocalizationKit

extension ShareImageQuoteView {
    var shareContent: String {
        let content = favorite?.text ?? quote?.text ?? ""
        let author = favorite?.author ?? quote?.author ?? ""
        return String(
            format: String(\MotivationStrings.shareTemplate),
            locale: LocalizationController.shared.locale,
            content,
            author
        )
    }

    var quoteText: String { favorite?.text ?? quote?.text ?? "" }

    var quoteAuthor: String {
        favorite?.author ?? quote?.author ?? String(\MotivationStrings.authorUnknown)
    }

    func resolvedLayoutSize(for image: UIImage) -> CGSize? {
        if let preferred = preferredLayoutSize() { return preferred }
        if image.size.width > 0, image.size.height > 0 { return image.size }
        return nil
    }

    func preferredLayoutSize() -> CGSize? {
        if let layoutSize, layoutSize.width > 0, layoutSize.height > 0 { return layoutSize }
        if let favorite, let width = favorite.imageWidth, let height = favorite.imageHeight, width > 0, height > 0 {
            let scale = max(UIScreen.main.scale, 1)
            return CGSize(width: CGFloat(width) / scale, height: CGFloat(height) / scale)
        }
        return nil
    }

    func copyToClipboard() {
        UIPasteboard.general.string = shareContent
        showCopiedBadge = true
        showCopiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopiedBadge = false }
    }

    func presentSnapshotFailureAlert() { activeSaveAlert = .snapshotFailure }

    func isLikelyBlank(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return true }
        let width = 8, height = 8, bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let context = CGContext(
            data: &data, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return true }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hasOpaquePixel = false
        var hasNonWhitePixel = false
        for idx in stride(from: 0, to: data.count, by: 4) {
            let r = data[idx], g = data[idx + 1], b = data[idx + 2], a = data[idx + 3]
            if a > 10 {
                hasOpaquePixel = true
                if r < 245 || g < 245 || b < 245 {
                    hasNonWhitePixel = true
                    break
                }
            }
        }
        return !hasOpaquePixel || !hasNonWhitePixel
    }
}
