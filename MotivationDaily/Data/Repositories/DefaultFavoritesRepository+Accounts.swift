import Foundation

struct OwnedFavorites: Codable {
    var legacyOwner: String?
    var accounts: [String: [FavoriteQuote]] = [:]
}

extension DefaultFavoritesRepository {
    var ownedKey: String { storageKey + ".owners.v1" }
    var guestKey: String { storageKey + ".guest.v1" }
    var imagePrefix: String {
        if let ownerID { return "accounts/" + ownerID + "/" }
        return (try? readOwners().legacyOwner) == nil ? "unclaimed/" : "guest/"
    }

    func readOwners() throws -> OwnedFavorites {
        guard let stored = userDefaults.object(forKey: ownedKey) else { return OwnedFavorites() }
        guard let data = stored as? Data else { throw CocoaError(.coderReadCorrupt) }
        return try decoder.decode(OwnedFavorites.self, from: data)
    }

    func writeOwners(_ state: OwnedFavorites) throws {
        userDefaults.set(try encoder.encode(state), forKey: ownedKey)
    }

    func loadOwnedFavorites(ownerID: String) throws -> [FavoriteQuote] {
        var state = try readOwners()
        if state.legacyOwner == nil {
            let legacy = try readLegacyFavorites()
            var merged = state.accounts[ownerID] ?? []
            for favorite in legacy where !merged.contains(where: { $0.id == favorite.id }) {
                let migrated = try migrateLegacyFavorite(favorite)
                merged.append(migrated)
            }
            state.accounts[ownerID] = merged
            state.legacyOwner = ownerID
            try writeOwners(state)
        }
        let favorites = state.accounts[ownerID] ?? []
        return favorites.map { item in
            let resolvedURL = Self.resolveLocalImageURL(
                for: item.localImagePath,
                fileManager: self.fileManager,
                imagesDirectoryURL: self.imagesDirectoryURL
            )
            return item.withResolvedLocalImageURL(resolvedURL)
        }
    }

    private func readLegacyFavorites() throws -> [FavoriteQuote] {
        guard let stored = userDefaults.object(forKey: storageKey) else { return [] }
        guard let data = stored as? Data else { throw CocoaError(.coderReadCorrupt) }
        return try decoder.decode([FavoriteQuote].self, from: data)
    }

    private func migrateLegacyFavorite(_ favorite: FavoriteQuote) throws -> FavoriteQuote {
        guard let path = favorite.localImagePath, !path.isEmpty else { return favorite }
        guard !path.contains("..") else { throw CocoaError(.fileReadInvalidFileName) }
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let bundledPath = path.hasPrefix("/") ? filename : path
        let current = imagesDirectoryURL.appendingPathComponent(bundledPath)
        let source = fileManager.fileExists(atPath: current.path) ? current : URL(fileURLWithPath: path)
        let relative = imagePrefix + UUID().uuidString + ".jpg"
        let destination = imagesDirectoryURL.appendingPathComponent(relative)
        if fileManager.fileExists(atPath: source.path) {
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(contentsOf: source).write(to: destination, options: .atomic)
        }
        return favorite.withLocalImagePath(relative)
    }
}
