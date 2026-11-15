import SwiftUI
import UIKit
import Combine

@MainActor
final class WallpaperViewModel: ObservableObject {
    struct RefreshPayload {
        let model: WallpaperUIModel
        let image: UIImage
        let requestSize: (width: Int, height: Int)
    }

    struct WallpaperUIModel: Equatable {
        let quote: Quote
        let imageURL: URL
        let imageSource: ImageSource
        let seed: String
        let imageCategoryTitle: String?
    }

    @Published private(set) var current: WallpaperUIModel?
    @Published var isRefreshing = false
    @Published var refreshError: String?
    @Published var currentUIImage: UIImage?

    private let imageLoader: any ImageLoading
    private let fetchWallpaperUseCase: FetchWallpaperUseCase
    private var refreshTask: Task<Void, Never>?
    private var prefetchTasks: [String: Task<RefreshPayload, Error>] = [:]

    init(fetchWallpaperUseCase: FetchWallpaperUseCase, imageLoader: any ImageLoading = ImageLoader.shared) {
        self.imageLoader = imageLoader
        self.fetchWallpaperUseCase = fetchWallpaperUseCase
    }

    func refresh(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        completion: ((Result<RefreshPayload, Error>) -> Void)? = nil
    ) {
        refreshTask?.cancel()
        refreshError = nil
        isRefreshing = true

        refreshTask = Task {
            do {
                let payload = try await loadPayload(
                    category: category,
                    aspectRatio: aspectRatio,
                    minimumLoaderDuration: 0.45
                )
                if Task.isCancelled { return }
                await MainActor.run {
                    currentUIImage = payload.image
                    current = payload.model
                    isRefreshing = false
                    completion?(.success(payload))
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    refreshError = userFacingMessage(for: error)
                    isRefreshing = false
                    completion?(.failure(error))
                }
            }
        }
    }

    func prefetch(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio
    ) async throws -> RefreshPayload {
        let targetSize = imageRequestSize(for: aspectRatio)
        let taskKey = prefetchTaskKey(
            category: category,
            aspectRatio: aspectRatio,
            targetSize: targetSize
        )

        if let existingTask = prefetchTasks[taskKey] {
            return try await existingTask.value
        }

        let task = Task<RefreshPayload, Error> {
            try await loadPayload(
                category: category,
                aspectRatio: aspectRatio,
                minimumLoaderDuration: nil
            )
        }
        prefetchTasks[taskKey] = task
        defer { prefetchTasks[taskKey] = nil }
        return try await task.value
    }

    func applyCached(_ model: WallpaperUIModel, image: UIImage?) {
        refreshTask?.cancel()
        refreshError = nil
        isRefreshing = false
        current = model
        if let image {
            currentUIImage = image
        }
    }

    func setCurrentImage(_ image: UIImage, for url: URL) {
        guard current?.imageURL == url else { return }
        currentUIImage = image
    }

    private func loadPayload(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        minimumLoaderDuration: TimeInterval?
    ) async throws -> RefreshPayload {
        let refreshStart = Date()
        let targetSize = imageRequestSize(for: aspectRatio)
        let wallpaper = try await fetchWallpaperUseCase.execute(
            category: category,
            width: targetSize.width,
            height: targetSize.height
        )
        let image = try await imageLoader.load(url: wallpaper.imageURL)

        if let minimumLoaderDuration {
            let elapsed = Date().timeIntervalSince(refreshStart)
            if elapsed < minimumLoaderDuration {
                try await Task.sleep(nanoseconds: UInt64((minimumLoaderDuration - elapsed) * 1_000_000_000))
            }
        }

        if Task.isCancelled {
            throw CancellationError()
        }

        let model = WallpaperUIModel(
            quote: wallpaper.quote,
            imageURL: wallpaper.imageURL,
            imageSource: wallpaper.imageSource,
            seed: wallpaper.seed,
            imageCategoryTitle: wallpaper.imageCategoryTitle
        )
        return RefreshPayload(model: model, image: image, requestSize: targetSize)
    }

    private func prefetchTaskKey(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        targetSize: (width: Int, height: Int)
    ) -> String {
        "\(category?.rawValue ?? "random")|\(aspectRatio.rawValue)|\(targetSize.width)x\(targetSize.height)"
    }
}
