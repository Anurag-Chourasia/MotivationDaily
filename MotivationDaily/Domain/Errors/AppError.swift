import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case network(status: Int)
    case networkMessage(String)
    case decoding(String)
    case storage(String)
    case emptyResponse
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .network(let status):
            switch status {
            case 401, 403:
                return "Request blocked by the server."
            case 404:
                return "Requested resource was not found."
            case 408:
                return "Request timed out. Please try again."
            case 429:
                return "Too many requests right now. Please wait a moment and try again."
            case 500...599:
                return "Server is temporarily unavailable. Please try again."
            default:
                return "Network error (status: \(status))."
            }
        case .networkMessage(let message):
            return message
        case .decoding(let message):
            return "Response parsing failed. \(message)"
        case .storage(let message):
            return "Storage error. \(message)"
        case .emptyResponse:
            return "No data received from the server."
        case .unknown(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .network(429):
            return "Try again in a few seconds."
        case .network(let status) where (500...599).contains(status):
            return "Please retry shortly."
        case .network:
            return "Check your network connection and retry."
        case .emptyResponse, .decoding:
            return "Please refresh again."
        case .storage:
            return "Restart the app and try again."
        case .invalidURL, .networkMessage, .unknown:
            return nil
        }
    }
}
