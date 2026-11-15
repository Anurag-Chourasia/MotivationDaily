import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct HomeActionRailView: View {
    let isSaved: Bool
    let selectedRatio: WallpaperAspectRatio
    let onSelectRatio: (WallpaperAspectRatio) -> Void
    let onToggleFavorite: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: \.fourteen) {
            ratioMenu
            Button(action: onToggleFavorite) {
                SideActionIconView(
                    isSaved ? \.heartFill : \.heart,
                    isSaved ? \.saved : \.favourites,
                    tint: isSaved ? \.red : \.white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.contentSaveButton)

            Button(action: onShare) {
                SideActionIconView(\.share, \.share)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(.contentShareButton)
        }
        .frame(width: \.p100)
    }

    private var ratioMenu: some View {
        Menu {
            ForEach(WallpaperAspectRatio.allCases) { ratio in
                Button(action: { onSelectRatio(ratio) }) {
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
        .accessibilityIdentifier(.contentRatioButton)
    }
}
