import Foundation
import CryptoKit

final class DefaultWallpaperRepository: WallpaperRepository {
    private let quoteRepository: any QuoteRepository
    private let imageRepository: any ImageRepository

    init(
        quoteRepository: any QuoteRepository,
        imageRepository: any ImageRepository
    ) {
        self.quoteRepository = quoteRepository
        self.imageRepository = imageRepository
    }

    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
        let safeWidth = max(width, 1)
        let safeHeight = max(height, 1)

        let quote: Quote
        if let category {
            quote = try await quoteRepository.fetchByCategory(category)
        } else {
            quote = try await quoteRepository.fetchRandom()
        }

        let seed = Self.sha256Hex("\(quote.text)|\(quote.author ?? "")").prefix(16)
        let imageCacheKey = "\(safeWidth)x\(safeHeight)|\(seed)"

        let imageURL: URL
        if let category {
            do {
                imageURL = try await imageRepository.imageURL(
                    for: category,
                    width: safeWidth,
                    height: safeHeight,
                    cacheKey: imageCacheKey
                )
            } catch {
                imageURL = imageRepository.randomImageURL(
                    width: safeWidth,
                    height: safeHeight,
                    cacheKey: imageCacheKey
                )
            }
        } else {
            imageURL = imageRepository.randomImageURL(
                width: safeWidth,
                height: safeHeight,
                cacheKey: imageCacheKey
            )
        }

        return Wallpaper(
            quote: quote,
            imageURL: imageURL,
            imageSource: .picsum,
            imageCategoryTitle: category?.rawValue,
            seed: String(seed)
        )
    }

    private static func sha256Hex(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
