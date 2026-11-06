import UIKit
import Combine
import LocalizationKit

struct FeedLaneKey: Hashable {
    let categoryRawValue: String
    let ratioRawValue: String
    let imageWidth: Int
    let imageHeight: Int

    init(category: CategoryKey?, ratio: WallpaperAspectRatio, imageSize: (width: Int, height: Int)) {
        categoryRawValue = category?.rawValue ?? "random"
        ratioRawValue = ratio.rawValue
        imageWidth = imageSize.width
        imageHeight = imageSize.height
    }
}

struct FeedCoordinate: Hashable {
    let lane: FeedLaneKey
    let depth: Int
}

@MainActor
final class FeedCacheCoordinator: ObservableObject {
    @Published var pageCache: [FeedCoordinate: FeedPageViewModel.FeedPageContent] = [:]
    @Published var depthByLane: [FeedLaneKey: Int] = [:]
    @Published var visitedDepthsByLane: [FeedLaneKey: [Int]] = [:]
    @Published var ratioQuoteOverrides: [FeedCoordinate: Quote] = [:]

    private var prewarmInFlight: Set<FeedCoordinate> = []
    private var activeFetchTasks: [FeedCoordinate: Task<Void, Never>] = [:]

    let verticalRenderRadius = 1
    let horizontalRenderRadius = 1
    let prewarmDepthRadius = 2
    let maxPrewarmInFlightCount = 3
    let visitedDepthLimit = 120

    func cachedContent(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        pageVM: FeedPageViewModel
    ) -> FeedPageViewModel.FeedPageContent? {
        let key = coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
        guard let cached = pageCache[key] else { return nil }
        return adaptContent(cached, for: ratio)
    }

    func laneKey(category: CategoryKey?, ratio: WallpaperAspectRatio, pageVM: FeedPageViewModel) -> FeedLaneKey {
        let requestSize = pageVM.imageRequestSize(for: ratio)
        return FeedLaneKey(
            category: category,
            ratio: ratio,
            imageSize: requestSize
        )
    }

    func coordinate(category: CategoryKey?, depth: Int, ratio: WallpaperAspectRatio, pageVM: FeedPageViewModel) -> FeedCoordinate {
        FeedCoordinate(
            lane: laneKey(category: category, ratio: ratio, pageVM: pageVM),
            depth: max(depth, 0)
        )
    }

    func coordinateIdentity(_ coordinate: FeedCoordinate) -> String {
        "\(coordinate.lane.categoryRawValue)|\(coordinate.lane.ratioRawValue)|\(coordinate.lane.imageWidth)x\(coordinate.lane.imageHeight)|d\(coordinate.depth)"
    }

    func isCurrentCoordinate(
        _ value: FeedCoordinate,
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        pageVM: FeedPageViewModel
    ) -> Bool {
        value == coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
    }

    func recordVisitedDepth(_ depth: Int, lane: FeedLaneKey) {
        var depths = visitedDepthsByLane[lane] ?? []
        if let existingIndex = depths.firstIndex(of: depth) {
            depths.remove(at: existingIndex)
        }
        depths.append(depth)
        if depths.count > visitedDepthLimit {
            depths.removeFirst(depths.count - visitedDepthLimit)
        }
        visitedDepthsByLane[lane] = depths
    }

    func cancelAllFetchTasks() {
        for task in activeFetchTasks.values {
            task.cancel()
        }
        activeFetchTasks.removeAll()
    }

    func clearLaneCache(category: CategoryKey?, ratio: WallpaperAspectRatio, pageVM: FeedPageViewModel) {
        let lane = laneKey(category: category, ratio: ratio, pageVM: pageVM)
        pageCache = pageCache.filter { $0.key.lane != lane }
        depthByLane[lane] = 0
        visitedDepthsByLane[lane] = []
    }

    func navigateTo(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        forceFetch: Bool,
        quoteOverride: Quote? = nil,
        minimumLoaderDuration: TimeInterval? = nil,
        pageVM: FeedPageViewModel,
        isConnected: Bool,
        categories: [Category],
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        let target = coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)

        if !forceFetch, let cached = pageCache[target] {
            depthByLane[target.lane] = depth
            recordVisitedDepth(depth, lane: target.lane)
            let adapted = adaptContent(cached, for: ratio)
            pageCache[target] = adapted
            pageVM.applyCached(adapted)
            prewarmWindow(
                around: category,
                depth: depth,
                ratio: ratio,
                categories: categories,
                pageVM: pageVM,
                isConnected: isConnected
            )
            pruneRenderWindow(
                selectedCategory: category,
                selectedRatio: ratio,
                currentDepth: depth,
                categories: categories,
                pageVM: pageVM
            )
            onSuccess?()
            return
        }

        fetchCoordinate(
            category: category,
            depth: depth,
            ratio: ratio,
            coordinate: target,
            quoteOverride: quoteOverride,
            minimumLoaderDuration: minimumLoaderDuration,
            pageVM: pageVM,
            isConnected: isConnected,
            categories: categories,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    func fetchCoordinate(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        coordinate: FeedCoordinate,
        quoteOverride: Quote?,
        minimumLoaderDuration: TimeInterval?,
        pageVM: FeedPageViewModel,
        isConnected: Bool,
        categories: [Category],
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {
        guard isConnected else {
            pageVM.refreshError = String(\CommonStrings.errorsNetworkUnreachable)
            onFailure?()
            return
        }

        if activeFetchTasks[coordinate] != nil {
            return
        }

        let task = Task {
            defer {
                Task { @MainActor in
                    activeFetchTasks.removeValue(forKey: coordinate)
                }
            }
            do {
                let content = try await pageVM.loadForCurrentPage(
                    category: category,
                    aspectRatio: ratio,
                    quoteOverride: quoteOverride,
                    minimumLoaderDuration: minimumLoaderDuration,
                    cacheIdentity: coordinateIdentity(coordinate)
                )
                if Task.isCancelled { return }

                await MainActor.run {
                    pageCache[coordinate] = content
                    depthByLane[coordinate.lane] = depth
                    ratioQuoteOverrides.removeValue(forKey: coordinate)
                    recordVisitedDepth(depth, lane: coordinate.lane)

                    if isCurrentCoordinate(coordinate, category: category, depth: depth, ratio: ratio, pageVM: pageVM) {
                        pageVM.applyCached(content)
                    }
                    prewarmWindow(
                        around: category,
                        depth: depth,
                        ratio: ratio,
                        categories: categories,
                        pageVM: pageVM,
                        isConnected: isConnected
                    )
                    pruneRenderWindow(
                        selectedCategory: category,
                        selectedRatio: ratio,
                        currentDepth: depth,
                        categories: categories,
                        pageVM: pageVM
                    )
                    onSuccess?()
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    onFailure?()
                }
            }
        }
        activeFetchTasks[coordinate] = task
    }

    func prewarmWindow(
        around category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        categories: [Category],
        pageVM: FeedPageViewModel,
        isConnected: Bool
    ) {
        guard isConnected else { return }

        for prewarmDepth in surroundingDepths(around: depth, radius: prewarmDepthRadius) {
            prewarmCell(category: category, depth: prewarmDepth, ratio: ratio, pageVM: pageVM)
        }

        for prewarmCategory in surroundingCategories(around: category, in: categories, radius: horizontalRenderRadius)
            where prewarmCategory != category {
            let alignedDepth = clampedDepth(depth, for: prewarmCategory, in: categories)
            prewarmCell(category: prewarmCategory, depth: alignedDepth, ratio: ratio, pageVM: pageVM)
        }
    }

    func prewarmCell(
        category: CategoryKey?,
        depth: Int,
        ratio: WallpaperAspectRatio,
        pageVM: FeedPageViewModel
    ) {
        let target = coordinate(category: category, depth: depth, ratio: ratio, pageVM: pageVM)
        let targetIdentity = coordinateIdentity(target)
        guard pageCache[target] == nil else { return }
        guard !prewarmInFlight.contains(target) else { return }
        guard activeFetchTasks[target] == nil else { return }
        guard prewarmInFlight.count < maxPrewarmInFlightCount else { return }

        prewarmInFlight.insert(target)
        Task {
            defer {
                Task { @MainActor in
                    prewarmInFlight.remove(target)
                }
            }

            do {
                let content = try await pageVM.prefetch(
                    category: category,
                    aspectRatio: ratio,
                    quoteOverride: await MainActor.run { ratioQuoteOverrides[target] },
                    cacheIdentity: targetIdentity
                )
                if Task.isCancelled { return }

                await MainActor.run {
                    pageCache[target] = content
                    ratioQuoteOverrides.removeValue(forKey: target)
                }
            } catch {
                // Ignore prewarm failures to keep feed responsive.
            }
        }
    }

    func pruneRenderWindow(
        selectedCategory: CategoryKey?,
        selectedRatio: WallpaperAspectRatio,
        currentDepth: Int,
        categories: [Category],
        pageVM: FeedPageViewModel
    ) {
        let keepCategories = Set(
            surroundingCategories(around: selectedCategory, in: categories, radius: horizontalRenderRadius)
                .map { $0?.rawValue ?? "random" }
        )
        let keepDepths = Set(surroundingDepths(around: currentDepth, radius: verticalRenderRadius))
        let requestSize = pageVM.imageRequestSize(for: selectedRatio)
        let currentLane = laneKey(category: selectedCategory, ratio: selectedRatio, pageVM: pageVM)
        let visitedDepths = Set(visitedDepthsByLane[currentLane] ?? [])

        pageCache = pageCache.filter { key, _ in
            if key.lane == currentLane {
                return visitedDepths.contains(key.depth) || keepDepths.contains(key.depth)
            }
            return key.lane.ratioRawValue == selectedRatio.rawValue
                && key.lane.imageWidth == requestSize.width
                && key.lane.imageHeight == requestSize.height
                && keepCategories.contains(key.lane.categoryRawValue)
                && keepDepths.contains(key.depth)
        }

        ratioQuoteOverrides = ratioQuoteOverrides.filter { key, _ in
            key.lane.ratioRawValue == selectedRatio.rawValue
                && key.lane.imageWidth == requestSize.width
                && key.lane.imageHeight == requestSize.height
                && keepCategories.contains(key.lane.categoryRawValue)
                && keepDepths.contains(key.depth)
        }
    }

    func adaptContent(
        _ content: FeedPageViewModel.FeedPageContent,
        for ratio: WallpaperAspectRatio
    ) -> FeedPageViewModel.FeedPageContent {
        let sourceImage = content.originalImage
        guard let targetAspect = ratio.value else {
            return FeedPageViewModel.FeedPageContent(
                quote: content.quote,
                image: sourceImage,
                originalImage: sourceImage,
                imageURL: content.imageURL,
                imageSource: content.imageSource,
                seed: content.seed,
                imageCategoryTitle: content.imageCategoryTitle
            )
        }
        let croppedImage = cropImage(sourceImage, toAspect: targetAspect)
        return FeedPageViewModel.FeedPageContent(
            quote: content.quote,
            image: croppedImage,
            originalImage: sourceImage,
            imageURL: content.imageURL,
            imageSource: content.imageSource,
            seed: content.seed,
            imageCategoryTitle: content.imageCategoryTitle
        )
    }

    func adaptCachedPages(for ratio: WallpaperAspectRatio) {
        pageCache = pageCache.mapValues { content in
            adaptContent(content, for: ratio)
        }
    }

    func cropImage(_ image: UIImage, toAspect aspect: CGFloat) -> UIImage {
        guard aspect > 0 else { return image }
        let normalized = normalizedImage(image)
        guard let cgImage = normalized.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 0, height > 0 else { return normalized }

        let currentAspect = width / height
        if abs(currentAspect - aspect) < 0.001 {
            return normalized
        }

        let cropRect: CGRect
        if currentAspect > aspect {
            let newWidth = height * aspect
            cropRect = CGRect(x: (width - newWidth) / 2.0, y: 0, width: newWidth, height: height)
        } else {
            let newHeight = width / aspect
            cropRect = CGRect(x: 0, y: (height - newHeight) / 2.0, width: width, height: newHeight)
        }

        guard let cropped = cgImage.cropping(to: cropRect.integral) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    func normalizedImage(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    func surroundingCategories(
        around center: CategoryKey?,
        in categories: [Category],
        radius: Int
    ) -> [CategoryKey?] {
        let allCategories: [CategoryKey?] = [nil] + categories.map(\.key)
        guard let centerIndex = allCategories.firstIndex(where: { $0 == center }) else {
            return [center]
        }

        var selected: [CategoryKey?] = []
        for offset in (-radius)...radius {
            var index = centerIndex + offset
            while index < 0 {
                index += allCategories.count
            }
            while index >= allCategories.count {
                index -= allCategories.count
            }
            let category = allCategories[index]
            if !selected.contains(where: { $0 == category }) {
                selected.append(category)
            }
        }
        return selected
    }

    func surroundingDepths(around center: Int, radius: Int) -> [Int] {
        var values: [Int] = []
        for offset in (-radius)...radius {
            let value = center + offset
            if value >= 0 {
                values.append(value)
            }
        }
        return values
    }

    func maxDepth(for category: CategoryKey?, in categories: [Category]) -> Int? {
        guard let category else { return nil }
        guard let quoteCount = categories.first(where: { $0.key == category })?.quoteCount, quoteCount > 0 else {
            return nil
        }
        return max(quoteCount - 1, 0)
    }

    func clampedDepth(_ depth: Int, for category: CategoryKey?, in categories: [Category]) -> Int {
        let nonNegativeDepth = max(depth, 0)
        guard let maxDepth = maxDepth(for: category, in: categories) else { return nonNegativeDepth }
        return min(nonNegativeDepth, maxDepth)
    }
}
