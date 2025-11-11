import Foundation

struct FetchWallpaperUseCase {
    private let repository: any WallpaperRepository

    init(repository: any WallpaperRepository) {
        self.repository = repository
    }

    func execute(category: CategoryKey?, width: Int, height: Int) async throws -> Wallpaper {
        try await repository.generate(category: category, width: width, height: height)
    }
}
