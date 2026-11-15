import Foundation

enum AppError: Error, Equatable, Sendable {
    case invalidURL
    case network(status: Int)
    case networkMessage(String)
    case decoding(String)
    case storage(String)
    case imageNotReady
    case emptyResponse
    case unknown(String)
}
