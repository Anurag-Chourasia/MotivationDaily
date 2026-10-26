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
            let favorites = try decoder.decode([FavoriteQuote].self, from: data)
            var needsMigration = false
            let normalized = favorites.map { item -> FavoriteQuote in
                guard let path = item.localImagePath, !path.isEmpty else { return item }
                if path.hasPrefix("/") {
                    needsMigration = true
                    let filename = URL(fileURLWithPath: path).lastPathComponent
                    return FavoriteQuote(
                        id: item.id,
                        text: item.text,
                        author: item.author,
                        source: item.source,
                        categoryKey: item.categoryKey,
                        imageURL: item.imageURL,
                        localImagePath: filename,
                        ratioRawValue: item.ratioRawValue,
                        imageWidth: item.imageWidth,
                        imageHeight: item.imageHeight,
                        savedDate: item.savedDate
                    )
                }
                return item
            }
            if needsMigration {
                try? saveFavorites(normalized)
            }
            return normalized
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
        let fileName = "\(safeName).jpg"
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            throw AppError.storage("Failed to store favorite image: \(error.localizedDescription)")
        }
    }

    func removeImage(at localPath: String) {
        guard !localPath.isEmpty else { return }
        let fileName = localPath.hasPrefix("/") ? URL(fileURLWithPath: localPath).lastPathComponent : localPath
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
        if localPath.hasPrefix("/"), fileManager.fileExists(atPath: localPath) {
            try? fileManager.removeItem(atPath: localPath)
        }
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
