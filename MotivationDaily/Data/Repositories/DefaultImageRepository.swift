import Foundation

final class DefaultImageRepository: ImageRepository {
    private let picsumFactory: PicsumURLFactory

    init(
        picsumFactory: PicsumURLFactory
    ) {
        self.picsumFactory = picsumFactory
    }

    func randomImageURL(width: Int, height: Int, cacheKey: String?) -> URL {
        picsumFactory.url(width: width, height: height, cacheKey: cacheKey)
    }

    func imageURL(for _: CategoryKey, width: Int, height: Int, cacheKey: String?) async throws -> URL {
        randomImageURL(width: width, height: height, cacheKey: cacheKey)
    }
}
