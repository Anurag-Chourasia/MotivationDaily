import Foundation

/// Persistent disk cache for quote catalog items in Motivation Daily.
/// Persists fetched quotes to disk atomically to ensure truthful offline catalog behavior.
final class QuoteDiskCache: @unchecked Sendable {
    static let shared = QuoteDiskCache()
    private let fileURL: URL

    init(directory: URL? = nil) {
        let root = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let cacheDir = root.appendingPathComponent("QuoteCatalogCache-v1", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        self.fileURL = cacheDir.appendingPathComponent("quotes.json")
    }

    var entryCount: Int {
        load().count
    }

    var fileSizeBytes: Int {
        (try? Data(contentsOf: fileURL))?.count ?? 0
    }

    var formattedFileSize: String {
        let bytes = fileSizeBytes
        guard bytes > 0 else { return "0 KB" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    func save(_ quotes: [Quote]) {
        guard !quotes.isEmpty else { return }
        var current = load()
        current.append(contentsOf: quotes)

        // Deduplicate quotes by text and author
        var seen = Set<String>()
        var deduped: [Quote] = []
        for q in current.reversed() {
            let key = (q.text + "|" + (q.author ?? "")).lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                deduped.append(q)
            }
        }
        let capped = Array(deduped.reversed().suffix(300))
        if let data = try? JSONEncoder().encode(capped) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func load() -> [Quote] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }
        return decoded
    }

    func load(category: CategoryKey?) -> Quote? {
        let quotes = load()
        guard !quotes.isEmpty else { return nil }
        if let category {
            let matching = quotes.filter { $0.categoryKey == category }
            if !matching.isEmpty { return matching.randomElement() }
        }
        return quotes.randomElement()
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
