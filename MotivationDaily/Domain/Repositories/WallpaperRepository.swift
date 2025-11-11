import Foundation

protocol WallpaperRepository {
    func generate(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper
}
