import Foundation
import FoundationKit

final class DefaultFavoritesRepository: FavoritesRepository, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let storageKey: String
    private let ownerID: String?
    private let logger: (any AppLogger)?
    private struct OwnedFavorites: Codable {
        var legacyOwner: String?
        var accounts: [String: [FavoriteQuote]] = [:]
    }
    private var ownedKey: String { storageKey + ".owners.v1" }
    private var guestKey: String { storageKey + ".guest.v1" }
    private var imagePrefix: String {
        if let ownerID { return "accounts/" + ownerID + "/" }
        return (try? readOwners().legacyOwner) == nil ? "unclaimed/" : "guest/"
    }
    private let imagesDirectoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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
        let dir = imagesRootURL ?? baseDirectory.appendingPathComponent("FavoriteImages", isDirectory: true)
        self.imagesDirectoryURL = dir

        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            try? fileManager.createDirectory(
                at: imagesDirectoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    func resolveImageURL(for localPath: String) -> URL? {
        Self.resolveLocalImageURL(
            for: localPath,
            fileManager: fileManager,
            imagesDirectoryURL: imagesDirectoryURL
        )
    }

    static func resolveLocalImageURL(
        for localImagePath: String?,
        fileManager: FileManager = .default,
        imagesDirectoryURL: URL? = nil
    ) -> URL? {
        guard let localImagePath, !localImagePath.isEmpty, !localImagePath.contains("..") else { return nil }

        let filename = localImagePath.hasPrefix("/")
            ? URL(fileURLWithPath: localImagePath).lastPathComponent
            : localImagePath

        let baseDirectory = imagesDirectoryURL ?? {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            return base.appendingPathComponent("FavoriteImages", isDirectory: true)
        }()

        let fileURL = baseDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }

        if localImagePath.hasPrefix("/"), fileManager.fileExists(atPath: localImagePath) {
            return URL(fileURLWithPath: localImagePath)
        }

        return nil
    }

    private func ensureImagesDirectoryExists() throws {
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
            } catch {
                throw AppError.storage("Failed to prepare image storage: \(error.localizedDescription)")
            }
        }
    }

    func loadFavorites() throws -> [FavoriteQuote] {
        if let ownerID { return try loadOwnedFavorites(ownerID: ownerID) }
        let key = try readOwners().legacyOwner == nil ? storageKey : guestKey
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            let favorites = try decoder.decode([FavoriteQuote].self, from: data)
            var needsMigration = false
            let normalized = favorites.map { item -> FavoriteQuote in
                let filename: String?
                if let path = item.localImagePath, !path.isEmpty {
                    if path.hasPrefix("/") {
                        needsMigration = true
                        filename = URL(fileURLWithPath: path).lastPathComponent
                    } else {
                        filename = path
                    }
                } else {
                    filename = nil
                }
                let resolvedURL = Self.resolveLocalImageURL(
                    for: filename,
                    fileManager: self.fileManager,
                    imagesDirectoryURL: self.imagesDirectoryURL
                )
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
                    savedDate: item.savedDate,
                    resolvedLocalImageURL: resolvedURL
                )
            }
            if needsMigration {
                do {
                    try saveFavorites(normalized)
                } catch {
                    logger?.log("Non-fatal: failed to persist normalized favorites: \(error.localizedDescription)", level: .warning)
                }
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

    func storeImageData(_ data: Data, for quoteID: String) throws -> String {
        try ensureImagesDirectoryExists()

        let safeName = makeSafeFileName(from: quoteID)
        let fileName = imagePrefix + "\(safeName).jpg"
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            throw AppError.storage("Failed to store favorite image: \(error.localizedDescription)")
        }
    }

    func removeImage(at localPath: String) {
        guard !localPath.isEmpty, !localPath.contains("..") else { return }
        if ownerID != nil || (try? readOwners().legacyOwner) != nil {
            guard localPath.hasPrefix(imagePrefix) else { return }
        }
        let path = localPath.hasPrefix("/") ? URL(fileURLWithPath: localPath).lastPathComponent : localPath
        let fileURL = imagesDirectoryURL.appendingPathComponent(path)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    private func readOwners() throws -> OwnedFavorites {
        guard let stored = userDefaults.object(forKey: ownedKey) else { return OwnedFavorites() }
        guard let data = stored as? Data else { throw CocoaError(.coderReadCorrupt) }
        return try decoder.decode(OwnedFavorites.self, from: data)
    }

    private func writeOwners(_ state: OwnedFavorites) throws {
        userDefaults.set(try encoder.encode(state), forKey: ownedKey)
    }

    private func loadOwnedFavorites(ownerID: String) throws -> [FavoriteQuote] {
        var state = try readOwners()
        if state.legacyOwner == nil {
            let legacy: [FavoriteQuote]
            if let stored = userDefaults.object(forKey: storageKey) {
                guard let data = stored as? Data else { throw CocoaError(.coderReadCorrupt) }
                legacy = try decoder.decode([FavoriteQuote].self, from: data)
            } else {
                legacy = []
            }
            var merged = state.accounts[ownerID] ?? []
            for favorite in legacy where !merged.contains(where: { $0.id == favorite.id }) {
                var migrated = favorite
                if let path = favorite.localImagePath, !path.isEmpty {
                    guard !path.contains("..") else { throw CocoaError(.fileReadInvalidFileName) }
                    let filename = URL(fileURLWithPath: path).lastPathComponent
                    let bundledPath = path.hasPrefix("/") ? filename : path
                    let current = imagesDirectoryURL.appendingPathComponent(bundledPath)
                    let source = fileManager.fileExists(atPath: current.path) ? current : URL(fileURLWithPath: path)
                    let relative = imagePrefix + UUID().uuidString + ".jpg"
                    let destination = imagesDirectoryURL.appendingPathComponent(relative)
                    if fileManager.fileExists(atPath: source.path) {
                        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                        // Atomic copy permits safe retry after an interrupted migration.
                        try Data(contentsOf: source).write(to: destination, options: .atomic)
                    }
                    migrated = favorite.withLocalImagePath(relative)
                }
                merged.append(migrated)
            }
            state.accounts[ownerID] = merged
            state.legacyOwner = ownerID
            // One write commits ownership and metadata only after all image copies succeed.
            // The legacy key and original images remain unchanged as recovery backups.
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
