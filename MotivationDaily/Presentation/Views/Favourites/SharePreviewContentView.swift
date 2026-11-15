import SwiftUI
import DesignTokensKit
import LocalizationKit

struct SharePreviewContentView: View {
    let compositeImage: UIImage?
    let isPreparingImage: Bool

    var body: some View {
        Group {
            if let compositeImage {
                Image(uiImage: compositeImage)
                    .resizable().scaledToFit().frame(maxHeight: \.p300).cornerRadius(\.twelve)
                Text(\.previewShareTitle)
                    .font(\.caption).foregroundColor(\.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, \.sixteen)
            } else if isPreparingImage {
                HStack(spacing: \.ten) {
                    ProgressView()
                    Text(\.preparingImage).font(\.caption).foregroundColor(\.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, \.sixteen)
            }
        }
    }
}
