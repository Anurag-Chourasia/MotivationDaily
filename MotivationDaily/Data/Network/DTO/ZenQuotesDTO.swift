import Foundation

struct ZenQuoteDTO: Decodable {
    let q: String
    let a: String
}

struct ZenErrorDTO: Decodable {
    let error: String?
}
