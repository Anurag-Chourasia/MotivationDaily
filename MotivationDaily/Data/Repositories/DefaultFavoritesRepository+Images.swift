import Foundation
import FoundationKit

extension DefaultFavoritesRepository {
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
        if fileManager.fileExists(atPath: fileURL.path) { return fileURL }

        if localImagePath.hasPrefix("/"), fileManager.fileExists(atPath: localImagePath) {
            return URL(fileURLWithPath: localImagePath)
        }
        return nil
    }

    func ensureImagesDirectoryExists() throws {
        if !fileManager.fileExists(atPath: imagesDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
            } catch {
                throw AppError.storage("Failed to prepare image storage: \(error.localizedDescription)")
            }
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

    func makeSafeFileName(from source: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        var output = ""
        output.reserveCapacity(min(source.count, 80))
        for scalar in source.unicodeScalars {
            if allowed.contains(scalar) { output.append(Character(scalar)) }
            else { output.append("-") }
        }
        let trimmed = output.trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        if trimmed.isEmpty { return UUID().uuidString }
        if trimmed.count > 80 { return String(trimmed.prefix(80)) }
        return trimmed
    }
}
