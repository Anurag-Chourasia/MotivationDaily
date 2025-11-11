import SwiftUI
import UIKit
import Combine

enum WallpaperAspectRatio: String, CaseIterable, Identifiable {
    case oneToOne = "1:1"
    case sixteenToNine = "16:9"
    case nineToSixteen = "9:16"
    case fullScreen = "Fullscreen"

    var id: String { rawValue }

    var value: CGFloat? {
        switch self {
        case .oneToOne:
            return 1.0
        case .sixteenToNine:
            return 16.0 / 9.0
        case .nineToSixteen:
            return 9.0 / 16.0
        case .fullScreen:
            return nil
        }
    }

    var components: (width: CGFloat, height: CGFloat)? {
        switch self {
        case .oneToOne:
            return (1, 1)
        case .sixteenToNine:
            return (16, 9)
        case .nineToSixteen:
            return (9, 16)
        case .fullScreen:
            return nil
        }
    }
}

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

    private let fetchWallpaperUseCase: FetchWallpaperUseCase
    private var refreshTask: Task<Void, Never>?
    private var prefetchTasks: [String: Task<RefreshPayload, Error>] = [:]

    init(fetchWallpaperUseCase: FetchWallpaperUseCase) {
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

    func imageRequestSize(for aspectRatio: WallpaperAspectRatio) -> (width: Int, height: Int) {
        imageRequestSize(
            for: aspectRatio,
            screenSize: UIScreen.main.bounds.size,
            scale: UIScreen.main.scale
        )
    }

    func imageRequestSize(
        for aspectRatio: WallpaperAspectRatio,
        screenSize: CGSize,
        scale: CGFloat
    ) -> (width: Int, height: Int) {
        let safeScale = max(scale, 1)
        let screenWidth = max(screenSize.width * safeScale, 1)
        let screenHeight = max(screenSize.height * safeScale, 1)

        guard let ratio = aspectRatio.components else {
            return (width: Int(ceil(screenWidth)), height: Int(ceil(screenHeight)))
        }

        let multiplier = min(screenWidth / ratio.width, screenHeight / ratio.height)

        let width = max(Int(ceil(ratio.width * multiplier)), 1)
        let height = max(Int(ceil(ratio.height * multiplier)), 1)
        return (width, height)
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
        let image = try await ImageLoader.shared.load(url: wallpaper.imageURL)

        if let minimumLoaderDuration {
            let elapsed = Date().timeIntervalSince(refreshStart)
            if elapsed < minimumLoaderDuration {
                try await Task.sleep(
                    nanoseconds: UInt64((minimumLoaderDuration - elapsed) * 1_000_000_000)
                )
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
        return RefreshPayload(
            model: model,
            image: image,
            requestSize: targetSize
        )
    }

    private func prefetchTaskKey(
        category: CategoryKey?,
        aspectRatio: WallpaperAspectRatio,
        targetSize: (width: Int, height: Int)
    ) -> String {
        "\(category?.rawValue ?? "random")|\(aspectRatio.rawValue)|\(targetSize.width)x\(targetSize.height)"
    }

    private func userFacingMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Could not refresh at the moment."
        }

        if let local = error as? LocalizedError, let description = local.errorDescription {
            return description
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "You appear to be offline. Check your connection and try again."
            case .timedOut:
                return "Request timed out. Please try again."
            default:
                break
            }
        }

        return "Could not refresh at the moment."
    }
}
