import Foundation

final class DefaultFavoritesRepository: FavoritesRepository {
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let storageKey: String
    private let imagesDirectoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        storageKey: String = "favoriteQuotes"
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.storageKey = storageKey
        let baseDirectory =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.imagesDirectoryURL = baseDirectory.appendingPathComponent("FavoriteImages", isDirectory: true)

        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try? fileManager.createDirectory(
                at: imagesDirectoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    func loadFavorites() throws -> [FavoriteQuote] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try decoder.decode([FavoriteQuote].self, from: data)
        } catch {
            throw AppError.storage("Failed to decode favorites: \(error.localizedDescription)")
        }
    }

    func saveFavorites(_ favorites: [FavoriteQuote]) throws {
        do {
            let encoded = try encoder.encode(favorites)
            userDefaults.set(encoded, forKey: storageKey)
        } catch {
            throw AppError.storage("Failed to save favorites: \(error.localizedDescription)")
        }
    }

    func storeImageData(_ data: Data, for quoteID: String) throws -> String {
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
            } catch {
                throw AppError.storage("Failed to prepare image storage: \(error.localizedDescription)")
            }
        }

        let safeName = makeSafeFileName(from: quoteID)
        let fileURL = imagesDirectoryURL.appendingPathComponent("\(safeName).jpg")

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            throw AppError.storage("Failed to store favorite image: \(error.localizedDescription)")
        }
    }

    func removeImage(at localPath: String) {
        guard !localPath.isEmpty else { return }
        let fileURL = URL(fileURLWithPath: localPath)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try? fileManager.removeItem(at: fileURL)
    }

    private func makeSafeFileName(from source: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        var output = ""
        output.reserveCapacity(min(source.count, 80))

        for scalar in source.unicodeScalars {
            if allowed.contains(scalar) {
                output.append(Character(scalar))
            } else {
                output.append("-")
            }
        }

        let trimmed = output.trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        if trimmed.isEmpty {
            return UUID().uuidString
        }

        if trimmed.count > 80 {
            return String(trimmed.prefix(80))
        }

        return trimmed
    }
}
