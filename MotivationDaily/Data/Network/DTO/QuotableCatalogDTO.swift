import Foundation

struct QuotableTagDTO: Decodable {
    let _id: String
    let name: String
    let slug: String
    let quoteCount: Int
}

struct QuotableQuotesPageDTO: Decodable {
    let count: Int
    let totalCount: Int
    let page: Int
    let totalPages: Int
    let lastItemIndex: Int?
    let results: [QuotableQuoteDTO]
}
