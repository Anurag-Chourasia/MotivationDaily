import SwiftUI
import DesignTokensKit
import LocalizationKit

struct FavoriteCellMetaView: View {
    let favorite: FavoriteQuote

    var body: some View {
        VStack(alignment: .leading, spacing: \.ten) {
            Text("\"\(favorite.text)\"")
                .font(\.headline)
                .foregroundColor(\.primary)
                .lineSpacing(\.p3)

            HStack(spacing: \.eight) {
                categoryTagView
                tagPill(favorite.source.titleKeyPath)
            }

            Text(formattedAuthor)
                .font(\.subheadline)
                .italic()
                .foregroundColor(\.secondary)
        }
        .padding(\.fourteen)
    }

    private var formattedAuthor: String {
        let author = favorite.author ?? String(\MotivationStrings.authorUnknown)
        return "— \(author)"
    }

    @ViewBuilder
    private var categoryTagView: some View {
        if let raw = favorite.categoryKey?.rawValue, !raw.isEmpty {
            let formatted = raw.replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            tagPill(verbatim: formatted)
        } else {
            tagPill(\.randomCategory)
        }
    }

    private func tagPill(_ keyPath: KeyPath<MotivationStrings, String>) -> some View {
        Text(keyPath)
            .font(\.caption2).foregroundColor(\.secondary)
            .padding(.horizontal, \.eight).padding(.vertical, \.four)
            .background(\.grouped).clipShape(Capsule())
    }

    private func tagPill(verbatim: String) -> some View {
        Text(verbatim.uppercased())
            .font(\.caption2).foregroundColor(\.secondary)
            .padding(.horizontal, \.eight).padding(.vertical, \.four)
            .background(\.grouped).clipShape(Capsule())
    }
}
