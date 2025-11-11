import Foundation

struct Wallpaper: Codable, Equatable {
    let quote: Quote
    let imageURL: URL
    let imageSource: ImageSource
    let imageCategoryTitle: String?
    let seed: String
}
