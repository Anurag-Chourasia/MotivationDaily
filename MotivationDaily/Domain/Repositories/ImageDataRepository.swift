import Foundation

protocol ImageDataRepository: Sendable {
    func fetchData(for url: URL) async throws -> Data
    func cachedData(for url: URL) async -> Data?
}

extension ImageDataRepository {
    func cachedData(for url: URL) async -> Data? { nil }
}

struct BasicImageDataRepository: ImageDataRepository {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchData(for url: URL) async throws -> Data {
        if url.isFileURL {
            let data = try Data(contentsOf: url)
            guard !data.isEmpty else { throw AppError.emptyResponse }
            return data
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.emptyResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.network(status: httpResponse.statusCode)
        }
        guard !data.isEmpty else {
            throw AppError.emptyResponse
        }
        return data
    }
}
