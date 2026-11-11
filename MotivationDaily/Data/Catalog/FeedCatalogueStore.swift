import Foundation

actor FeedCatalogueStore: FeedCatalogueRepository {
    struct CatalogueCategory: Codable {
        let keyRawValue: String
        let displayName: String
        let quoteCount: Int
    }

    struct CatalogueImageMeta: Codable {
        let id: String
        let author: String
        let width: Int
        let height: Int
        let url: URL
        let downloadURL: URL

        var stableSeed: String {
            "picsum-\(id)-\(author)"
        }
    }

    struct Snapshot: Codable {
        var categories: [CatalogueCategory]
        var randomQuotes: [Quote]
        var quotesByCategory: [String: [Quote]]
        var images: [CatalogueImageMeta]
        var updatedAt: Date

        static let randomKey = "__random__"

        static func empty(now: Date = Date()) -> Snapshot {
            Snapshot(
                categories: [],
                randomQuotes: [],
                quotesByCategory: [:],
                images: [],
                updatedAt: now
            )
        }
    }

    private let apiService: APIService
    private let quotableClient: QuotableClient
    private let zenClient: ZenQuotesClient
    private let adviceSlipClient: AdviceSlipClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager: FileManager
    private let allowsNetworkSync: Bool

    private let snapshotURL: URL

    private var snapshot: Snapshot
    private var didLoadFromDisk = false

    private var seedTask: Task<Void, Never>?
    private var fullSyncTask: Task<Void, Never>?
    private var sessionQuotesCache: [String: [Quote]] = [:]
    private let sessionImageOffset: Int = Int.random(in: 1...100_000)

    init(
        apiService: APIService,
        quotableClient: QuotableClient,
        zenClient: ZenQuotesClient,
        adviceSlipClient: AdviceSlipClient,
        fileManager: FileManager = .default,
        cacheRootURL: URL? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        allowsNetworkSync: Bool = true,
        seededSnapshot: Snapshot? = nil
    ) {
        self.apiService = apiService
        self.quotableClient = quotableClient
        self.zenClient = zenClient
        self.adviceSlipClient = adviceSlipClient
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
        self.allowsNetworkSync = allowsNetworkSync
        self.snapshot = Snapshot.empty()

        let root = cacheRootURL
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let catalogueRoot = root.appendingPathComponent("feed-catalogue", isDirectory: true)
        self.snapshotURL = catalogueRoot.appendingPathComponent("snapshot-v1.json")

        try? fileManager.createDirectory(at: catalogueRoot, withIntermediateDirectories: true)
        self.encoder.outputFormatting = [.sortedKeys]

        if let seededSnapshot {
            self.snapshot = seededSnapshot
            self.didLoadFromDisk = true
            Self.write(snapshot: seededSnapshot, to: snapshotURL, encoder: self.encoder)
        }
    }

    func warmup() {
        ensureSeedRefreshStarted()
    }

    func categories(fallback: [Category]) async -> [Category] {
        await ensureSnapshotLoaded()

        var currentCategories: [Category] = []
        for category in snapshot.categories where !category.keyRawValue.isEmpty {
            let item = Category(
                key: CategoryKey(rawValue: category.keyRawValue),
                displayName: category.displayName,
                quoteCount: category.quoteCount
            )
            currentCategories.append(item)
        }
        currentCategories.sort {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }

        if !currentCategories.isEmpty {
            return currentCategories
        }

        ensureSeedRefreshStarted()
        return fallback
    }

    func randomQuoteCount() async -> Int {
        await ensureSnapshotLoaded()
        return snapshot.randomQuotes.count
    }

    func page(
        category: CategoryKey?,
        depth: Int,
        quoteOverride: Quote?
    ) async throws -> FeedCataloguePage {
        await ensureSeedReady(minRandomQuotes: 20, minImages: 20)

        let clampedDepth = max(depth, 0)
        let x = categoryIndex(for: category)
        let quote = try await resolveQuote(category: category, depth: clampedDepth, quoteOverride: quoteOverride)

        guard let imageMeta = resolveImageMeta(x: x, y: clampedDepth) else {
            throw FeedCatalogueError.unavailable
        }

        return FeedCataloguePage(
            quote: quote,
            imageURL: imageMeta.downloadURL,
            imageSource: .picsum,
            seed: stableSeed(x: x, y: clampedDepth, quote: quote, imageMeta: imageMeta),
            imageCategoryTitle: category?.rawValue
        )
    }

    private func ensureSeedRefreshStarted() {
        guard allowsNetworkSync else { return }
        Task { [self] in
            await ensureSnapshotLoaded()
            if seedTask != nil {
                return
            }

            let task = Task { [weak self] in
                guard let self else { return }
                await self.runSeedRefresh()
            }
            seedTask = task
            await task.value
            seedTask = nil
        }
    }

    private func ensureSeedReady(minRandomQuotes: Int, minImages: Int) async {
        await ensureSnapshotLoaded()
        let hasSeed = snapshot.randomQuotes.count >= minRandomQuotes && snapshot.images.count >= minImages
        if hasSeed {
            startBackgroundFullSyncIfNeeded()
            return
        }

        guard allowsNetworkSync else { return }

        if let running = seedTask {
            await running.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runSeedRefresh()
        }
        seedTask = task
        await task.value
        seedTask = nil
    }

    private func ensureSnapshotLoaded() async {
        guard !didLoadFromDisk else { return }
        defer { didLoadFromDisk = true }

        guard fileManager.fileExists(atPath: snapshotURL.path) else { return }
        guard let data = try? Data(contentsOf: snapshotURL) else { return }
        guard let decoded = try? decoder.decode(Snapshot.self, from: data) else { return }
        snapshot = decoded
    }

    private func runSeedRefresh() async {
        async let tagsResult = fetchTagCategories()
        async let randomQuotesResult = fetchZenQuotes()
        async let imagesResult = fetchPicsumImages(page: 1, limit: 100)

        let tags = (try? await tagsResult) ?? []
        let randomQuotes = (try? await randomQuotesResult) ?? []
        let images = (try? await imagesResult) ?? []

        if !tags.isEmpty {
            snapshot.categories = tags
        }

        if !randomQuotes.isEmpty {
            snapshot.randomQuotes = deduplicatedQuotes(randomQuotes)
            snapshot.quotesByCategory[Snapshot.randomKey] = snapshot.randomQuotes
        }

        if !images.isEmpty {
            snapshot.images = mergeImages(existing: snapshot.images, adding: images)
        }

        let preferredSeedCategories: [String] = ["inspirational", "wisdom", "success", "happiness", "life"]
        for slug in preferredSeedCategories {
            if snapshot.quotesByCategory[slug]?.isEmpty == false { continue }
            if let quotes = try? await fetchQuotes(slug: slug, minCount: 20), !quotes.isEmpty {
                snapshot.quotesByCategory[slug] = quotes
            }
        }

        snapshot.updatedAt = Date()
        persistSnapshot()
        startBackgroundFullSyncIfNeeded()
    }

    func waitForBackgroundSync() async {
        await fullSyncTask?.value
    }

    private func startBackgroundFullSyncIfNeeded() {
        guard allowsNetworkSync else { return }
        guard fullSyncTask == nil else { return }

        fullSyncTask = Task { [weak self] in
            guard let self else { return }
            await self.performBackgroundFullSync()
            await self.clearFullSyncTask()
        }
    }

    private func performBackgroundFullSync() async {
        await ensureSnapshotLoaded()

        if snapshot.images.count < 1200 {
            for page in 2...30 {
                guard !Task.isCancelled else { return }
                guard let more = try? await fetchPicsumImages(page: page, limit: 100), !more.isEmpty else {
                    break
                }
                snapshot.images = mergeImages(existing: snapshot.images, adding: more)
            }
        }

        let categoriesForSync: [String] = snapshot.categories.prefix(20).map(\.keyRawValue)
        for slug in categoriesForSync {
            guard !Task.isCancelled else { return }
            let existingCount = snapshot.quotesByCategory[slug]?.count ?? 0
            if existingCount >= 300 {
                continue
            }

            if let quotes = try? await fetchQuotes(slug: slug, minCount: 300), !quotes.isEmpty {
                snapshot.quotesByCategory[slug] = quotes
            }
        }

        snapshot.updatedAt = Date()
        persistSnapshot()
    }

    private func fetchTagCategories() async throws -> [CatalogueCategory] {
        let tags = try await quotableClient.fetchTags()
        let sorted = tags
            .filter { $0.quoteCount > 0 }
            .map { tag in
                CatalogueCategory(
                    keyRawValue: tag.slug,
                    displayName: tag.name,
                    quoteCount: tag.quoteCount
                )
            }
            .sorted { lhs, rhs in
                if lhs.quoteCount == rhs.quoteCount {
                    return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
                }
                return lhs.quoteCount > rhs.quoteCount
            }

        var seenSlugs = Set<String>()
        var seenNames = Set<String>()
        var deduped: [CatalogueCategory] = []

        for category in sorted {
            let normalizedSlug = category.keyRawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedName = category.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalizedSlug.isEmpty || normalizedName.isEmpty {
                continue
            }
            if seenSlugs.contains(normalizedSlug) || seenNames.contains(normalizedName) {
                continue
            }
            seenSlugs.insert(normalizedSlug)
            seenNames.insert(normalizedName)
            deduped.append(category)
        }

        return deduped
    }

    private func fetchZenQuotes() async throws -> [Quote] {
        let entries = try await zenClient.fetchQuotes()
        return deduplicatedQuotes(
            entries.map { item in
                Quote(
                    id: UUID().uuidString,
                    text: item.q,
                    author: item.a,
                    source: .zenQuotes,
                    categoryKey: nil
                )
            }
        )
    }

    private func fetchPicsumImages(page: Int, limit: Int) async throws -> [CatalogueImageMeta] {
        let url = try apiService.makeURL(
            base: "https://picsum.photos",
            path: "/v2/list",
            queryItems: [
                URLQueryItem(name: "page", value: String(max(page, 1))),
                URLQueryItem(name: "limit", value: String(max(limit, 1)))
            ]
        )

        let data = try await apiService.getData(url, cachePolicy: .reloadIgnoringLocalCacheData)
        let dtos = try decoder.decode([PicsumImageDTO].self, from: data)
        let targetWidth = 1080
        let targetHeight = 1920
        return dtos.map {
            let optimizedURL = URL(string: "https://picsum.photos/id/\($0.id)/\(targetWidth)/\(targetHeight)") ?? $0.downloadURL
            return CatalogueImageMeta(
                id: $0.id,
                author: $0.author,
                width: targetWidth,
                height: targetHeight,
                url: URL(string: $0.url) ?? URL(fileURLWithPath: "/"),
                downloadURL: optimizedURL
            )
        }
    }

    private func fetchQuotes(slug: String, minCount: Int) async throws -> [Quote] {
        let requestedCount = max(minCount, 20)
        let perPage = 150
        var page = 1
        var all: [Quote] = []
        var totalPages = 1

        repeat {
            guard !Task.isCancelled else { break }
            let response = try await quotableClient.fetchQuotes(tags: slug, page: page, limit: perPage)
            let categoryKey = CategoryKey(rawValue: slug)
            let mapped = response.results.map {
                Quote(
                    id: $0._id,
                    text: $0.content,
                    author: $0.author,
                    source: .quotable,
                    categoryKey: categoryKey
                )
            }
            all.append(contentsOf: mapped)
            totalPages = max(response.totalPages, 1)
            page += 1
        } while all.count < requestedCount && page <= totalPages

        return deduplicatedQuotes(all)
    }

    private func resolveQuote(
        category: CategoryKey?,
        depth: Int,
        quoteOverride: Quote?
    ) async throws -> Quote {
        if let quoteOverride {
            return quoteOverride
        }

        let bucketKey = category?.rawValue ?? Snapshot.randomKey

        if bucketKey == Snapshot.randomKey {
            await extendRandomQuotesIfNeeded(forDepth: depth)
        } else if let category {
            let requestedCount = min(
                max(depth + 1, 20),
                quoteLimit(for: category) ?? Int.max
            )
            let currentCount = snapshot.quotesByCategory[bucketKey]?.count ?? 0
            if currentCount < requestedCount, allowsNetworkSync {
                if let quotes = try? await fetchQuotes(slug: category.rawValue, minCount: requestedCount), !quotes.isEmpty {
                    snapshot.quotesByCategory[bucketKey] = quotes
                    snapshot.updatedAt = Date()
                    persistSnapshot()
                }
            }
        }

        let rawAvailable = snapshot.quotesByCategory[bucketKey]
            ?? (bucketKey == Snapshot.randomKey ? snapshot.randomQuotes : nil)
            ?? []
        let available = sessionQuotes(for: bucketKey, from: rawAvailable)

        guard !available.isEmpty else {
            if bucketKey == Snapshot.randomKey, let advice = try? await fetchAdviceSlipQuote() {
                snapshot.randomQuotes = deduplicatedQuotes(snapshot.randomQuotes + [advice])
                snapshot.quotesByCategory[Snapshot.randomKey] = snapshot.randomQuotes
                snapshot.updatedAt = Date()
                persistSnapshot()
                sessionQuotesCache.removeValue(forKey: Snapshot.randomKey)
                return advice
            }
            if let random = snapshot.randomQuotes.first {
                return random
            }
            throw FeedCatalogueError.unavailable
        }

        if bucketKey == Snapshot.randomKey {
            let index = positiveMod(depth, available.count)
            return available[index]
        }

        if let category {
            let limit = quoteLimit(for: category) ?? available.count
            guard depth < limit else {
                throw FeedCatalogueError.unavailable
            }
        }

        if depth < available.count {
            return available[depth]
        }

        if let last = available.last {
            return last
        }

        throw FeedCatalogueError.unavailable
    }

    private func quoteLimit(for category: CategoryKey) -> Int? {
        snapshot.categories.first(where: { $0.keyRawValue == category.rawValue })?.quoteCount
    }

    private func extendRandomQuotesIfNeeded(forDepth depth: Int) async {
        guard depth >= snapshot.randomQuotes.count else { return }
        guard allowsNetworkSync else { return }

        var attempts = 0
        var hasChanges = false

        while depth >= snapshot.randomQuotes.count && attempts < 3 {
            attempts += 1

            if let newQuotes = try? await fetchZenQuotes(), !newQuotes.isEmpty {
                let combined = deduplicatedQuotes(snapshot.randomQuotes + newQuotes)
                if combined.count > snapshot.randomQuotes.count {
                    snapshot.randomQuotes = combined
                    hasChanges = true
                    continue
                }
            }

            if let advice = try? await fetchAdviceSlipQuote() {
                let combined = deduplicatedQuotes(snapshot.randomQuotes + [advice])
                if combined.count > snapshot.randomQuotes.count {
                    snapshot.randomQuotes = combined
                    hasChanges = true
                }
            }
        }

        if hasChanges {
            snapshot.quotesByCategory[Snapshot.randomKey] = snapshot.randomQuotes
            snapshot.updatedAt = Date()
            persistSnapshot()
        }
    }

    private func fetchAdviceSlipQuote() async throws -> Quote {
        let advice = try await adviceSlipClient.fetchRandomAdvice()
        return Quote(
            id: "advice-\(advice.id)",
            text: advice.advice,
            author: "Advice Slip",
            source: .adviceSlip,
            categoryKey: nil
        )
    }

    private func categoryIndex(for category: CategoryKey?) -> Int {
        guard let category else { return 0 }
        if let matched = snapshot.categories.firstIndex(where: { $0.keyRawValue == category.rawValue }) {
            return matched + 1
        }

        let digest = category.rawValue.unicodeScalars.reduce(into: 0) { partial, scalar in
            partial = (partial * 31) ^ Int(scalar.value)
        }
        return abs(digest % 997) + 1
    }

    private func sessionQuotes(for bucketKey: String, from source: [Quote]) -> [Quote] {
        guard !source.isEmpty else { return [] }
        if let existing = sessionQuotesCache[bucketKey], !existing.isEmpty {
            if existing.count < source.count {
                let existingIds = Set(existing.compactMap(\.id))
                let newItems = source.filter { quote in
                    guard let id = quote.id else { return false }
                    return !existingIds.contains(id)
                }.shuffled()
                let updated = existing + newItems
                sessionQuotesCache[bucketKey] = updated
                return updated
            }
            return existing
        }
        let shuffled = source.shuffled()
        sessionQuotesCache[bucketKey] = shuffled
        return shuffled
    }

    private func resolveImageMeta(x: Int, y: Int) -> CatalogueImageMeta? {
        guard !snapshot.images.isEmpty else {
            return nil
        }

        let hashValue = deterministicHash(x: x, y: y &+ sessionImageOffset)
        let index = Int(hashValue % UInt64(snapshot.images.count))
        return snapshot.images[index]
    }

    private func stableSeed(x: Int, y: Int, quote: Quote, imageMeta: CatalogueImageMeta) -> String {
        let quotePart = quote.id ?? quote.text
        let raw = "\(x)|\(y)|\(quotePart)|\(imageMeta.stableSeed)"
        return "seed-\(stableStringHash(raw))"
    }

    private static func write(snapshot: Snapshot, to url: URL, encoder: JSONEncoder) {
        guard let data = try? encoder.encode(snapshot) else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            // Best effort cache persistence.
        }
    }

    private func persistSnapshot() {
        Self.write(snapshot: snapshot, to: snapshotURL, encoder: encoder)
    }

    private func mergeImages(
        existing: [CatalogueImageMeta],
        adding: [CatalogueImageMeta]
    ) -> [CatalogueImageMeta] {
        var seen = Set(existing.map(\.id))
        var merged = existing
        for image in adding where !seen.contains(image.id) {
            merged.append(image)
            seen.insert(image.id)
        }
        return merged
    }

    private func deduplicatedQuotes(_ quotes: [Quote]) -> [Quote] {
        var seen = Set<String>()
        var deduped: [Quote] = []

        for quote in quotes {
            let key = (quote.text + "|" + (quote.author ?? "")).lowercased()
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            deduped.append(quote)
        }

        return deduped
    }

    private func positiveMod(_ value: Int, _ modulus: Int) -> Int {
        guard modulus > 0 else { return 0 }
        let remainder = value % modulus
        return remainder >= 0 ? remainder : remainder + modulus
    }

    private func deterministicHash(x: Int, y: Int) -> UInt64 {
        var v1 = UInt64(bitPattern: Int64(x &* 73856093))
        var v2 = UInt64(bitPattern: Int64(y &* 19349663))
        v1 ^= (v2 << 13) | (v2 >> 51)
        v2 ^= (v1 << 7) | (v1 >> 57)
        return v1 &+ v2 &+ 0x9E3779B97F4A7C15
    }

    private func stableStringHash(_ value: String) -> String {
        var hash: UInt64 = 1469598103934665603
        let prime: UInt64 = 1099511628211
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return String(hash, radix: 16)
    }

    private func clearFullSyncTask() {
        fullSyncTask = nil
    }
}
