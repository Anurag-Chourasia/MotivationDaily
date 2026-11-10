import Foundation

protocol WallpaperRepository: Sendable {
    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper
}
