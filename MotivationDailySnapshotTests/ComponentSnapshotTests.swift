import XCTest
import SwiftUI
import SnapshotTestKit
@testable import MotivationDaily

@MainActor
final class ComponentSnapshotTests: XCTestCase {

    private var defaults: UserDefaults!
    private var defaultsSuite: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // A wrong destination must fail, not turn the entire suite into skips.
        XCTAssertEqual(SnapshotDevice.current, .iPhone11, "Run snapshots on iPhone 11")
        defaultsSuite = "MotivationDaily.Snapshots.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: defaultsSuite))
        if ProcessInfo.processInfo.environment["CI"] != nil {
            XCTAssertFalse(SnapshotAssert.isRecordModeEnabled, "CI must only compare reviewed baselines")
        }
    }

    override func tearDownWithError() throws {
        if let defaultsSuite { defaults.removePersistentDomain(forName: defaultsSuite) }
        defaults = nil
        try super.tearDownWithError()
    }

    private func makeContainer() -> AppContainer {
        AppContainer(arguments: ["-UITestMode", "-UITestClearFavorites"], favoritesDefaults: defaults)
    }

    // MARK: - Empty Favorites View

    func testEmptyFavoritesView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = EmptyFavoritesView()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "empty-favorites"
        )
    }

    // MARK: - Connectivity Banner View

    func testConnectivityBannerView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = ConnectivityBannerView(
            message: "No internet connection. Displaying offline quotes.",
            isWarning: true,
            accent: .orange
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "connectivity-banner"
        )
    }

    // MARK: - Quote Card View

    func testQuoteCardView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let quote = Quote(
            id: "snap-1",
            text: "The secret of getting ahead is getting started.",
            author: "Mark Twain",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "wisdom")
        )

        let view = QuoteCardView(
            quote: quote,
            dominantColor: .blue,
            overlayOpacity: 0.5,
            compactStyle: false,
            showsDepthEffects: true
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "quote-card"
        )
    }

    // MARK: - About View

    func testAboutView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = AboutView()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "about-screen"
        )
    }

    // MARK: - Quote Card Container View

    func testQuoteCardContainerView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let quote = Quote(
            id: "snap-container-1",
            text: "Focus on what matters most.",
            author: "Anonymous",
            source: .zenQuotes,
            categoryKey: nil
        )

        let view = QuoteCardContainerView(
            quote: quote,
            compactStyle: false,
            showsDepthEffects: true,
            cardHeight: 280
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "quote-card-container"
        )
    }

    // MARK: - Side Action Icon View

    func testSideActionIconView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = SideActionIconView(
            systemName: "heart.fill",
            label: "Saved",
            tint: .red
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "side-action-icon"
        )
    }

    // MARK: - Gradient Overlay View

    func testGradientOverlayView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = GradientOverlayView(isReducedForScroll: false)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "gradient-overlay"
        )
    }

    // MARK: - Background Wallpaper View

    func testBackgroundWallpaperView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let view = BackgroundWallpaperView(
            url: nil,
            aspectRatio: 1.0
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "background-wallpaper"
        )
    }

    // MARK: - Favorite Cell View

    func testFavoriteCellView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let quote = Quote(
            id: "snap-fav-1",
            text: "Peace comes from within. Do not seek it without.",
            author: "Buddha",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "wisdom")
        )
        let favorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "1:1",
            imageWidth: 300,
            imageHeight: 300
        )

        let view = FavoriteCellView(
            favorite: favorite,
            imageURL: nil,
            onImageTap: {},
            onToggleFavorite: {},
            onImageDataResolved: { _ in }
        )
        .padding()

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "favorite-cell"
        )
    }

    // MARK: - Favorite List View

    func testFavoriteListView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let container = makeContainer()
        let quoteVM = container.makeQuoteViewModel()

        let view = FavoriteListView(
            quoteVM: quoteVM,
            onImageTap: { _ in }
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "favorite-list"
        )
    }

    // MARK: - Favorites View

    func testFavoritesView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let container = makeContainer()
        let quoteVM = container.makeQuoteViewModel()

        let view = FavoritesView(quoteVM: quoteVM)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "favorites-screen"
        )
    }

    // MARK: - Full Screen Image View

    struct FullScreenSnapshotWrapper: View {
        @State var isPresented = true
        let favorite: FavoriteQuote

        var body: some View {
            FullScreenImageView(
                favorite: favorite,
                favoriteImage: nil,
                isPresented: $isPresented,
                onImageDataResolved: nil
            )
        }
    }

    func testFullScreenImageView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let quote = Quote(
            id: "snap-fs-1",
            text: "Simplicity is prerequisite for reliability.",
            author: "Edsger W. Dijkstra",
            source: .zenQuotes,
            categoryKey: nil
        )
        let favorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "1:1",
            imageWidth: 300,
            imageHeight: 300
        )

        let view = FullScreenSnapshotWrapper(favorite: favorite)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "fullscreen-image"
        )
    }

    // MARK: - Share Image Quote View

    func testShareImageQuoteView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let quote = Quote(
            id: "snap-share-1",
            text: "Do what you can with all you have.",
            author: "Theodore Roosevelt",
            source: .zenQuotes,
            categoryKey: nil
        )
        let favorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "1:1",
            imageWidth: 300,
            imageHeight: 300
        )

        let view = ShareImageQuoteView(
            favorite: favorite,
            favoriteImage: nil,
            quote: quote,
            wallpaper: nil,
            layoutSize: CGSize(width: 300, height: 300)
        )

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "share-image-quote"
        )
    }

    // MARK: - Home cold-start surface
    // This synchronous snapshot captures the pre-task launch surface only.
    // Loaded feed behaviour is exercised by HomeFlowTests, not this image.

    func testHomeView() throws {
        guard SnapshotDevice.current == .iPhone11 else {
            throw XCTSkip("Skipping base iPhone 11 component test on \(SnapshotDevice.current?.rawValue ?? "unknown device")")
        }

        let container = makeContainer()
        let quoteVM = container.makeQuoteViewModel()
        let pageVM = container.makeFeedPageViewModel()

        let view = HomeView(quoteVM: quoteVM, pageVM: pageVM)

        SnapshotAssert.assertVariants(
            of: view,
            on: .iPhone11,
            named: "home-screen"
        )
    }
}
