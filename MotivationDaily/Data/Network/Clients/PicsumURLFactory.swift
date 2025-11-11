import Foundation

struct PicsumURLFactory {
    func url(width: Int, height: Int, cacheKey _: String?) -> URL {
        let safeWidth = max(width, 1)
        let safeHeight = max(height, 1)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "picsum.photos"
        components.path = "/\(safeWidth)/\(safeHeight)"
        // Always request a fresh random image from Picsum for each API fetch.
        let randomToken = "\(UUID().uuidString)-\(Int(Date().timeIntervalSince1970 * 1000))"
        components.queryItems = [URLQueryItem(name: "random", value: randomToken)]

        if let url = components.url {
            return url
        }

        return URL(string: "https://picsum.photos/1/1?random=fallback")
            ?? URL(fileURLWithPath: "/")
    }
}
