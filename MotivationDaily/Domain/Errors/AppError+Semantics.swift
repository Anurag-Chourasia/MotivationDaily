import Foundation

extension AppError {
    var semanticCode: SemanticCode {
        switch self {
        case .invalidURL: return .invalidURL
        case .network(let status):
            switch status {
            case 401, 403: return .blocked
            case 404: return .notFound
            case 408: return .timeout
            case 429: return .rateLimited
            case 500...599: return .serverUnavailable
            default: return .networkStatus(status)
            }
        case .networkMessage(let message):
            switch message {
            case "Invalid response.": return .invalidResponse
            case "Image load failed.": return .imageLoadFailed
            default: return .untrustedNetworkMessage
            }
        case .decoding: return .decoding
        case .imageNotReady: return .imageNotReady
        case .storage(let message):
            if message.hasPrefix("Image is not ready") { return .imageNotReady }
            return .storage
        case .emptyResponse: return .emptyResponse
        case .unknown: return .unknown
        }
    }

    var semanticRecovery: RecoverySemanticCode? {
        switch self {
        case .network(429): return .rateLimited
        case .network(let status) where (500...599).contains(status): return .serverUnavailable
        case .network: return .network
        case .emptyResponse, .decoding: return .refresh
        case .storage, .imageNotReady: return .storage
        case .invalidURL, .networkMessage, .unknown: return nil
        }
    }
}
