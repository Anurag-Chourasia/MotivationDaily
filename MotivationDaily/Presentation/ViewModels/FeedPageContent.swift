import UIKit

extension FeedPageViewModel {
    struct FeedPageContent {
        let quote: Quote
        let image: UIImage
        let originalImage: UIImage
        let imageURL: URL
        let imageSource: ImageSource
        let seed: String
        let imageCategoryTitle: String?

        init(
            quote: Quote,
            image: UIImage,
            originalImage: UIImage? = nil,
            imageURL: URL,
            imageSource: ImageSource,
            seed: String,
            imageCategoryTitle: String?
        ) {
            self.quote = quote
            self.image = image
            self.originalImage = originalImage ?? image
            self.imageURL = imageURL
            self.imageSource = imageSource
            self.seed = seed
            self.imageCategoryTitle = imageCategoryTitle
        }
    }
}
