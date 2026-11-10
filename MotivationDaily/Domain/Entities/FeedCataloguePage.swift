import Foundation

struct FeedCataloguePage: Sendable {
    let quote: Quote
    let imageURL: URL
    let imageSource: ImageSource
    let seed: String
    let imageCategoryTitle: String?

    init(
        quote: Quote,
        imageURL: URL,
        imageSource: ImageSource,
        seed: String,
        imageCategoryTitle: String?
    ) {
        self.quote = quote
        self.imageURL = imageURL
        self.imageSource = imageSource
        self.seed = seed
        self.imageCategoryTitle = imageCategoryTitle
    }
}
