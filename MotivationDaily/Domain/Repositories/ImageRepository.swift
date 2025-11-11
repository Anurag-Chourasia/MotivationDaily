import Foundation

protocol ImageRepository {
    func randomImageURL(width: Int, height: Int, cacheKey: String?) -> URL
    func imageURL(for key: CategoryKey, width: Int, height: Int, cacheKey: String?) async throws -> URL
}
