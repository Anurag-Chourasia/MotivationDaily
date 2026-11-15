import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

struct FullScreenActionRailView: View {
    @Binding var selectedRatio: WallpaperAspectRatio
    let onShare: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: \.fourteen) {
            Menu {
                ForEach(WallpaperAspectRatio.allCases) { ratio in
                    Button(action: { selectedRatio = ratio }) {
                        if ratio == selectedRatio {
                            Label(ratio.localizedTitle, \.checkmark)
                        } else {
                            Text(ratio.localizedTitle)
                        }
                    }
                }
            } label: {
                SideActionIconView(\.crop, label: selectedRatio.localizedTitle)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.favoritesFullScreenRatioButton)

            Button(action: onShare) {
                SideActionIconView(\.share, \.share)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.favoritesFullScreenShareButton)

            Button(action: onClose) {
                SideActionIconView(\.close, \.close)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.favoritesFullScreenCloseButton)
        }
        .frame(width: \.p100)
    }
}
