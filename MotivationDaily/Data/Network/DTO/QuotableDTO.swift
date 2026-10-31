import Foundation

struct QuotableQuoteDTO: Decodable {
    let _id: String
    let content: String
    let author: String

    enum CodingKeys: String, CodingKey {
        case _id
        case id
        case content
        case quote
        case author
    }

    init(_id: String, content: String, author: String) {
        self._id = _id
        self.content = content
        self.author = author
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let explicitId = try container.decodeIfPresent(String.self, forKey: ._id) {
            self._id = explicitId
        } else if let altId = try container.decodeIfPresent(String.self, forKey: .id) {
            self._id = altId
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys._id,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No _id or id found")
            )
        }

        if let explicitContent = try container.decodeIfPresent(String.self, forKey: .content) {
            self.content = explicitContent
        } else if let altQuote = try container.decodeIfPresent(String.self, forKey: .quote) {
            self.content = altQuote
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.content,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No content or quote found")
            )
        }

        self.author = try container.decode(String.self, forKey: .author)
    }
}
