import Foundation
import FoundationKit

final class DefaultFavoritesRepository: FavoritesRepository, @unchecked Sendable {
    let userDefaults: UserDefaults
    let fileManager: FileManager
    let storageKey: String
    let ownerID: String?
    let logger: (any AppLogger)?
    let imagesDirectoryURL: URL
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        storageKey: String = "favoriteQuotes",
        ownerID: UUID? = nil,
        imagesRootURL: URL? = nil,
        logger: (any AppLogger)? = nil
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.storageKey = storageKey
        self.ownerID = ownerID?.uuidString.lowercased()
        self.logger = logger
        let baseDirectory =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.imagesDirectoryURL = imagesRootURL ?? baseDirectory.appendingPathComponent("FavoriteImages", isDirectory: true)

        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try? fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
        }
    }

    func loadFavorites() throws -> [FavoriteQuote] {
        if let ownerID { return try loadOwnedFavorites(ownerID: ownerID) }
        let key = try readOwners().legacyOwner == nil ? storageKey : guestKey
        guard let data = userDefaults.data(forKey: key) else { return [] }

        do {
            let favorites = try decoder.decode([FavoriteQuote].self, from: data)
            var needsMigration = false
            let normalized = favorites.map { item -> FavoriteQuote in
                let filename = normalizeFilename(item.localImagePath, needsMigration: &needsMigration)
                let resolvedURL = Self.resolveLocalImageURL(
                    for: filename, fileManager: self.fileManager, imagesDirectoryURL: self.imagesDirectoryURL
                )
                let mapped = filename != nil ? item.withLocalImagePath(filename!) : item
                return mapped.withResolvedLocalImageURL(resolvedURL)
            }
            if needsMigration {
                try? saveFavorites(normalized)
            }
            return normalized
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.storage("Failed to decode favorites: \(error.localizedDescription)")
        }
    }

    func saveFavorites(_ favorites: [FavoriteQuote]) throws {
        do {
            let encoded = try encoder.encode(favorites)
            if let ownerID {
                _ = try loadOwnedFavorites(ownerID: ownerID)
                var state = try readOwners()
                state.accounts[ownerID] = favorites
                try writeOwners(state)
            } else {
                let key = try readOwners().legacyOwner == nil ? storageKey : guestKey
                userDefaults.set(encoded, forKey: key)
            }
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.storage("Failed to save favorites: \(error.localizedDescription)")
        }
    }

    private func normalizeFilename(_ path: String?, needsMigration: inout Bool) -> String? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("/") {
            needsMigration = true
            return URL(fileURLWithPath: path).lastPathComponent
        }
        return path
    }
}
