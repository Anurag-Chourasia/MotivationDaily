import SwiftUI
import UIKit
import DesignTokensKit

struct BackgroundWallpaperLayer: View {
    let image: UIImage?
    let frame: CGSize

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame.width, height: frame.height)
                    .clipped()
            } else {
                LinearGradient(
                    stops: [
                        ThemeColorStop(\.black, opacity: \.p0_85),
                        ThemeColorStop(\.ink),
                        ThemeColorStop(\.black, opacity: \.p0_9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: frame.width, height: frame.height)
            }
        }
    }
}
