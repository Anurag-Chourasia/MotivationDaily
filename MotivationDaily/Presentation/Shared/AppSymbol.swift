import SwiftUI

public enum AppSymbol: String, Sendable, CaseIterable {
    case checkmark = "checkmark"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case crop = "crop"
    case cropSquare = "crop.square"
    case docOnDocFill = "doc.on.doc.fill"
    case ellipsisCircle = "ellipsis.circle"
    case heartFill = "heart.fill"
    case heartSlash = "heart.slash"
    case line3HorizontalCircleFill = "line.3.horizontal.circle.fill"
    case paperplaneFill = "paperplane.fill"
    case photo = "photo"
    case photoFill = "photo.fill"
    case photoBadgeCheckmarkFill = "photo.badge.checkmark.fill"
    case quoteOpening = "quote.opening"
    case sparkles = "sparkles"
    case squareAndArrowDown = "square.and.arrow.down"
    case xmark = "xmark"
}

extension Image {
    public init(symbol: AppSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}

extension Label where Title == Text, Icon == Image {
    public init(_ titleKey: LocalizedStringKey, symbol: AppSymbol) {
        self.init(titleKey, systemImage: symbol.rawValue)
    }

    public init<S>(_ title: S, symbol: AppSymbol) where S: StringProtocol {
        self.init(title, systemImage: symbol.rawValue)
    }
}
