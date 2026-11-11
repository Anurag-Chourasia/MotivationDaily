import Foundation
import CommonNetworkingKit

final class DefaultImageDataRepository: ImageDataRepository {
    private let fetcher: any ImageDataFetching
    private let cache: (any ImageDataCaching)?

    init(fetcher: any ImageDataFetching, cache: (any ImageDataCaching)? = nil) {
        self.fetcher = fetcher
        self.cache = cache
    }

    func fetchData(for url: URL) async throws -> Data {
        try await fetcher.fetchData(for: url)
    }

    func cachedData(for url: URL) async -> Data? {
        await cache?.data(for: url)
    }
}
