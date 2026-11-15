import SwiftUI
import UIKit
import LocalizationKit

extension FeedPageViewModel {
    func imageRequestSize(for aspectRatio: WallpaperAspectRatio) -> (width: Int, height: Int) {
        imageRequestSize(
            for: aspectRatio,
            screenSize: UIScreen.main.bounds.size,
            scale: UIScreen.main.scale
        )
    }

    func imageRequestSize(
        for aspectRatio: WallpaperAspectRatio,
        screenSize: CGSize,
        scale: CGFloat
    ) -> (width: Int, height: Int) {
        let safeScale = max(scale, 1)
        let screenWidth = max(screenSize.width * safeScale, 1)
        let screenHeight = max(screenSize.height * safeScale, 1)

        guard let ratio = aspectRatio.components else {
            return (width: Int(ceil(screenWidth)), height: Int(ceil(screenHeight)))
        }

        let multiplier = min(screenWidth / ratio.width, screenHeight / ratio.height)
        let width = max(Int(ceil(ratio.width * multiplier)), 1)
        let height = max(Int(ceil(ratio.height * multiplier)), 1)
        return (width, height)
    }

    func userFacingMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedMessage()
        }

        if let local = error as? LocalizedError, let description = local.errorDescription {
            return description
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return String(\CommonStrings.errorsNetworkUnreachable)
            case .timedOut:
                return String(\MotivationStrings.errorTimeout)
            default:
                break
            }
        }

        return String(\MotivationStrings.errorRefresh)
    }
}
