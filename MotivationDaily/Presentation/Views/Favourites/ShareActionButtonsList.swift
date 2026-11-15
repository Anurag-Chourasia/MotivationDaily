import SwiftUI
import UIComponentsKit
import DesignTokensKit
import LocalizationKit

struct ShareActionButtonsList: View {
    let compositeImage: UIImage?
    let sourceImage: UIImage?
    let quoteOnlyImage: UIImage?
    let isSavingImage: Bool
    let showCopiedBadge: Bool
    let onShareComposite: () -> Void
    let onShareSource: () -> Void
    let onOpenSaveOptions: () -> Void
    let onShareQuoteOnly: () -> Void
    let onCopyQuote: () -> Void

    var body: some View {
        VStack(spacing: \.twelve) {
            Button(action: onShareComposite) {
                ShareButtonRowView(
                    symbol: \.photoBadgeCheckmarkFill,
                    title: \.shareQuoteAndImage,
                    subtitle: \.quoteEmbeddedInImage,
                    themeColor: \.blue
                )
            }
            .disabled(compositeImage == nil)
            .opacity(compositeImage == nil ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareQuoteAndImageButton)

            Button(action: onShareSource) {
                ShareButtonRowView(
                    symbol: \.photoFill,
                    title: \.shareImageOnly,
                    subtitle: \.wallpaperBackgroundOnly,
                    themeColor: \.turquoise
                )
            }
            .disabled(sourceImage == nil)
            .opacity(sourceImage == nil ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareImageOnlyButton)

            Button(action: onOpenSaveOptions) {
                saveToPhotosButtonContent
            }
            .disabled(cannotSave || isSavingImage)
            .opacity((cannotSave || isSavingImage) ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareSaveToPhotosButton)

            Button(action: onShareQuoteOnly) {
                ShareButtonRowView(
                    symbol: \.quoteOpening,
                    title: \.shareQuoteOnly,
                    subtitle: \.blackGradientBackground,
                    themeColor: \.green
                )
            }
            .accessibilityIdentifier(.shareQuoteOnlyButton)

            Button(action: onCopyQuote) {
                copyQuoteButtonContent
            }
            .accessibilityIdentifier(.shareCopyQuoteButton)
        }
    }

    private var cannotSave: Bool {
        sourceImage == nil && compositeImage == nil && quoteOnlyImage == nil
    }

    private var saveToPhotosButtonContent: some View {
        HStack(spacing: \.ten) {
            Image(\.squareAndArrowDown).font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(isSavingImage ? \.preparingImage : \.saveToPhotos)
                    .fontWeight(.semibold).font(\.body)
                Text(\.chooseWhatToSave).font(\.caption).foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
            if isSavingImage { ProgressView().tint(\.white) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [ThemeColorStop(\.oceanAction, opacity: \.p0_85), ThemeColorStop(\.oceanAction)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .foregroundColor(\.white).cornerRadius(\.twelve)
    }

    private var copyQuoteButtonContent: some View {
        HStack(spacing: \.ten) {
            Image(\.docOnDocFill).font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(\.copyQuote).fontWeight(.semibold).font(\.body)
                Text(\.pasteAnywhere).font(\.caption).foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
            if showCopiedBadge { Image(\.checkmarkCircleFill).foregroundColor(\.white) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [ThemeColorStop(\.orange, opacity: \.p0_8), ThemeColorStop(\.orange)],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .foregroundColor(\.white).cornerRadius(\.twelve)
    }
}
