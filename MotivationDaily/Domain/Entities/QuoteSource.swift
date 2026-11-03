import Foundation
import LocalizationKit

enum QuoteSource: String, Codable {
    case zenQuotes
    case quotable
    case quoteGarden
    case adviceSlip

    var titleKeyPath: KeyPath<MotivationStrings, String> {
        switch self {
        case .zenQuotes:
            return \.sourceZenQuotes
        case .quotable:
            return \.sourceQuotable
        case .quoteGarden:
            return \.sourceQuoteGarden
        case .adviceSlip:
            return \.sourceAdviceSlip
        }
    }
}
