import Foundation

extension AppError {
    enum SemanticCode: Equatable, Sendable {
        case invalidURL
        case blocked
        case notFound
        case timeout
        case rateLimited
        case serverUnavailable
        case networkStatus(Int)
        case invalidResponse
        case imageLoadFailed
        case untrustedNetworkMessage
        case decoding
        case storage
        case imageNotReady
        case emptyResponse
        case unknown
    }

    enum RecoverySemanticCode: Equatable, Sendable {
        case rateLimited
        case serverUnavailable
        case network
        case refresh
        case storage
    }
}
