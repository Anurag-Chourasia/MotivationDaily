import SwiftUI
import DesignTokensKit
import LocalizationKit

struct QuoteCardAuthorPillView: View {
    let author: String?
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: \.six) {
            Capsule()
                .fill(\.white, opacity: \.p0_5)
                .frame(width: \.p22_58, height: \.p2)
            Text(author ?? String(\MotivationStrings.authorUnknown))
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(\.white, opacity: \.p0_9)
            Capsule()
                .fill(\.white, opacity: \.p0_5)
                .frame(width: \.p22_58, height: \.p2)
        }
    }
}
