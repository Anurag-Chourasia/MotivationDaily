import XCTest
import SwiftUI
import UIKit
@testable import MotivationDaily

@MainActor
final class ViewUnitTests: XCTestCase {

    private func evaluate<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 844)) async {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            XCTFail("A connected window scene is required to host SwiftUI views")
            return
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        defer { window.isHidden = true; window.rootViewController = nil }
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        // Keep the view installed while SwiftUI runs appearance and task callbacks.
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.bounds.width, 0)
        XCTAssertGreaterThan(controller.view.bounds.height, 0)
    }

    func testAboutView() async {
        let view = AboutView()
        await evaluate(view)
    }

    func testEmptyFavoritesView() async {
        let view = EmptyFavoritesView()
        await evaluate(view)
    }

    func testConnectivityBannerView() async {
        let v1 = ConnectivityBannerView(message: "Connected", isWarning: false, accent: .green)
        await evaluate(v1)

        let v2 = ConnectivityBannerView(message: "Offline", isWarning: true, accent: .red)
        await evaluate(v2)
    }

    func testQuoteCardView() async {
        let quote = Quote(
            id: "qc-1",
            text: "Simplicity is the soul of efficiency.",
            author: "Austin Freeman",
            source: .zenQuotes,
            categoryKey: nil
        )

        let compact = QuoteCardView(
            quote: quote,
            dominantColor: .blue,
            overlayOpacity: 0.5,
            compactStyle: true,
            showsDepthEffects: true
        )
        await evaluate(compact)

        let regular = QuoteCardView(
            quote: quote,
            dominantColor: nil,
            overlayOpacity: 0.3,
            compactStyle: false,
            showsDepthEffects: false
        )
        await evaluate(regular)
    }

    func testQuoteCardContainerView() async {
        let quote = Quote(id: "qcc-1", text: "Work hard", author: "Unknown", source: .zenQuotes, categoryKey: nil)
        let v1 = QuoteCardContainerView(quote: quote, compactStyle: false, showsDepthEffects: true, cardHeight: 200)
        await evaluate(v1)

        let v2 = QuoteCardContainerView(quote: quote, compactStyle: true, showsDepthEffects: false, cardHeight: 150)
        await evaluate(v2)
    }

    func testSideActionIconView() async {
        let icon1 = SideActionIconView(systemName: "heart.fill", label: "Saved", tint: .red)
        await evaluate(icon1)

        let icon2 = SideActionIconView(systemName: "paperplane", label: "Share", tint: .white)
        await evaluate(icon2)

        let iconFallback = SideActionIconView(systemName: "nonexistent.icon.name.xyz", label: "Aspect", tint: .yellow)
        await evaluate(iconFallback)
    }

    func testGradientOverlayView() async {
        let v1 = GradientOverlayView(isReducedForScroll: false)
        await evaluate(v1)

        let v2 = GradientOverlayView(isReducedForScroll: true)
        await evaluate(v2)
    }

    func testBackgroundWallpaperView() async {
        let v1 = BackgroundWallpaperView(url: URL(string: "https://example.com/test.jpg"))
        await evaluate(v1)

        let v2 = BackgroundWallpaperView(url: nil, aspectRatio: 1.0)
        await evaluate(v2)
    }

    func testFavoriteCellView() async {
        let quote = Quote(id: "fc-1", text: "Quote text", author: "Author", source: .zenQuotes, categoryKey: nil)
        let favorite = FavoriteQuote(
            from: quote,
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "Full",
            imageWidth: 300,
            imageHeight: 600
        )

        var deleted = false
        var tapped = false

        let cell = FavoriteCellView(
            favorite: favorite,
            imageURL: URL(string: "https://example.com/fav.jpg"),
            onImageTap: { tapped = true },
            onToggleFavorite: { deleted = true },
            onImageDataResolved: { _ in }
        )
        await evaluate(cell)
        cell.onImageTap()
        XCTAssertTrue(tapped)
        cell.onToggleFavorite()
        XCTAssertTrue(deleted)
    }

    func testFavoriteListView() async {
        let container = AppContainer.live
        let quoteVM = container.makeQuoteViewModel()
        let q1 = Quote(id: "fav-l1", text: "Quote 1", author: "Author 1", source: .zenQuotes, categoryKey: nil)
        let q2 = Quote(id: "fav-l2", text: "Quote 2", author: "Author 2", source: .quotable, categoryKey: CategoryKey(rawValue: "wisdom"))
        quoteVM.addToFavorites(q1, localImageData: Data([0x01]))
        quoteVM.addToFavorites(q2, localImageData: Data([0x02]))

        var tappedFavorite: FavoriteQuote?
        let list = FavoriteListView(
            quoteVM: quoteVM,
            onImageTap: { tappedFavorite = $0 }
        )
        await evaluate(list)

        if let fav = quoteVM.favorites.first {
            list.onImageTap(fav)
            XCTAssertEqual(tappedFavorite?.id, fav.id)
        }
    }

    func testFavoritesView() async {
        let container = AppContainer.live
        let quoteVM = container.makeQuoteViewModel()
        let q1 = Quote(id: "fav-v1", text: "Quote 1", author: "Author 1", source: .zenQuotes, categoryKey: nil)
        quoteVM.addToFavorites(q1, localImageData: Data([0x01]))

        let favoritesView = FavoritesView(quoteVM: quoteVM)
        await evaluate(favoritesView)
    }

    struct FullScreenWrapper: View {
        @State var isPresented = true
        let favorite: FavoriteQuote?
        let favoriteImage: UIImage?

        var body: some View {
            FullScreenImageView(
                favorite: favorite,
                favoriteImage: favoriteImage,
                isPresented: $isPresented,
                onImageDataResolved: { _, _ in }
            )
        }
    }

    func testFullScreenImageView() async {
        let quote = Quote(id: "fs-1", text: "Full Screen Quote", author: "Author", source: .zenQuotes, categoryKey: nil)
        let favorite = FavoriteQuote(from: quote, imageURL: nil, localImagePath: nil, ratioRawValue: "1:1", imageWidth: 400, imageHeight: 400)

        let wrapper = FullScreenWrapper(favorite: favorite, favoriteImage: nil)
        await evaluate(wrapper)

        let wrapperWithImage = FullScreenWrapper(favorite: favorite, favoriteImage: UIImage())
        await evaluate(wrapperWithImage)

        let wrapperNil = FullScreenWrapper(favorite: nil, favoriteImage: nil)
        await evaluate(wrapperNil)
    }

    func testShareImageQuoteView() async {
        let quote = Quote(id: "sq-1", text: "Share Quote", author: "Author", source: .zenQuotes, categoryKey: nil)
        let favorite = FavoriteQuote(from: quote, imageURL: nil, localImagePath: nil, ratioRawValue: "1:1", imageWidth: 400, imageHeight: 400)
        let img = UIImage()

        let shareView = ShareImageQuoteView(
            favorite: favorite,
            favoriteImage: img,
            quote: quote,
            wallpaper: img,
            layoutSize: CGSize(width: 300, height: 300)
        )
        await evaluate(shareView)

        let shareViewQuoteOnly = ShareImageQuoteView(
            favorite: nil,
            favoriteImage: nil,
            quote: quote,
            wallpaper: nil,
            layoutSize: nil
        )
        await evaluate(shareViewQuoteOnly)
    }

    func testShareImageQuoteViewHelpers() async {
        let quote = Quote(id: "sqh-1", text: "Inspire", author: "Author", source: .zenQuotes, categoryKey: nil)
        let fav = FavoriteQuote(from: quote, imageURL: nil, localImagePath: nil, ratioRawValue: "1:1", imageWidth: 300, imageHeight: 300)
        let img = UIImage()

        let shareView = ShareImageQuoteView(
            favorite: fav,
            favoriteImage: img,
            quote: quote,
            wallpaper: img,
            layoutSize: CGSize(width: 300, height: 300)
        )

        XCTAssertNotNil(shareView.preferredLayoutSize())

        let shareViewNoSize = ShareImageQuoteView(
            favorite: nil,
            favoriteImage: nil,
            quote: quote,
            wallpaper: nil,
            layoutSize: nil
        )
        XCTAssertNil(shareViewNoSize.preferredLayoutSize())

        XCTAssertTrue(shareView.isLikelyBlank(UIImage()))

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let redImg = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        XCTAssertFalse(shareView.isLikelyBlank(redImg))

        shareView.copyToClipboard()
        shareView.presentSnapshotFailureAlert()
    }

    func testHomeView() async {
        let container = AppContainer.live
        let quoteVM = container.makeQuoteViewModel()
        let pageVM = container.makeFeedPageViewModel()

        let sampleQuote = Quote(id: "home-q1", text: "Live fully.", author: "Author", source: .zenQuotes, categoryKey: nil)
        let sampleImg = UIImage()
        let sampleContent = FeedPageViewModel.FeedPageContent(
            quote: sampleQuote,
            image: sampleImg,
            originalImage: sampleImg,
            imageURL: URL(string: "https://example.com/home.jpg")!,
            imageSource: .picsum,
            seed: "123",
            imageCategoryTitle: nil
        )
        pageVM.applyCached(sampleContent)

        let homeView = HomeView(quoteVM: quoteVM, pageVM: pageVM)
        await evaluate(homeView)
    }

    func testDefaultCardConfigurationAndImageOrientation() async throws {
        let quote = Quote(id: "defaults", text: "Default rendering", author: nil, source: .adviceSlip, categoryKey: nil)
        await evaluate(GradientOverlayView())
        await evaluate(QuoteCardContainerView(quote: quote, compactStyle: false))
        await evaluate(QuoteCardView(quote: quote, dominantColor: nil, overlayOpacity: 0.5, compactStyle: false))

        let container = AppContainer.live
        let view = HomeView(quoteVM: container.makeQuoteViewModel(), pageVM: container.makeFeedPageViewModel())
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 40))
        let image = renderer.image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 40))
        }
        let rotated = UIImage(cgImage: try XCTUnwrap(image.cgImage), scale: image.scale, orientation: .left)
        let normalized = view.normalizedImage(rotated)
        XCTAssertEqual(normalized.imageOrientation, .up)
        XCTAssertEqual(normalized.size, rotated.size)
        let cropped = view.cropImage(rotated, toAspect: 1)
        XCTAssertEqual(cropped.size.width, cropped.size.height, accuracy: 1)
    }

    func testHomeViewCalculations() async {
        let container = AppContainer.live
        let quoteVM = container.makeQuoteViewModel()
        let pageVM = container.makeFeedPageViewModel()
        let homeView = HomeView(quoteVM: quoteVM, pageVM: pageVM)

        // project
        XCTAssertEqual(homeView.project(100), 32)

        // wallpaperRect
        let zeroRect = homeView.wallpaperRect(in: .zero)
        XCTAssertEqual(zeroRect, .zero)

        let containerSize = CGSize(width: 300, height: 600)
        let fullRect = homeView.wallpaperRect(in: containerSize, ratio: .fullScreen)
        XCTAssertEqual(fullRect.size, containerSize)

        let squareRect = homeView.wallpaperRect(in: containerSize, ratio: .oneToOne)
        XCTAssertEqual(squareRect.width, 300)
        XCTAssertEqual(squareRect.height, 300)

        // quote card heights
        let compactRect = CGRect(x: 0, y: 0, width: 300, height: 200)
        XCTAssertEqual(homeView.minimumQuoteCardHeight(for: compactRect), 160)
        XCTAssertEqual(homeView.preferredQuoteCardHeight(for: compactRect), 248)
        _ = homeView.resolvedQuoteCardHeight(for: compactRect)

        let largeRect = CGRect(x: 0, y: 0, width: 300, height: 600)
        XCTAssertEqual(homeView.minimumQuoteCardHeight(for: largeRect), 220)
        XCTAssertEqual(homeView.preferredQuoteCardHeight(for: largeRect), 320)
        _ = homeView.resolvedQuoteCardHeight(for: largeRect)

        // laneKey & coordinate
        let lane = FeedLaneKey(category: nil, ratio: .fullScreen, imageSize: (300, 600))
        XCTAssertEqual(lane.categoryRawValue, "random")

        let catLane = FeedLaneKey(category: CategoryKey(rawValue: "life"), ratio: .oneToOne, imageSize: (300, 300))
        XCTAssertEqual(catLane.categoryRawValue, "life")

        let coord = FeedCoordinate(lane: lane, depth: 5)
        XCTAssertEqual(coord.depth, 5)

        // categoryFromRaw
        XCTAssertNil(homeView.categoryFromRaw("random"))
        XCTAssertEqual(homeView.categoryFromRaw("wisdom")?.rawValue, "wisdom")

        // surrounding categories and depths
        let surroundingCats = homeView.surroundingCategories(around: nil, radius: 2)
        XCTAssertFalse(surroundingCats.isEmpty)

        let surroundingDepths = homeView.surroundingDepths(around: 5, radius: 2)
        XCTAssertEqual(surroundingDepths, [3, 4, 5, 6, 7])

        let edgeDepths = homeView.surroundingDepths(around: 0, radius: 2)
        XCTAssertEqual(edgeDepths, [0, 1, 2])

        // categoryTitle & clampedDepth
        let catWithCount = Category(key: CategoryKey(rawValue: "wisdom"), displayName: "Wisdom", quoteCount: 15)
        XCTAssertEqual(homeView.categoryTitle(for: catWithCount), "Wisdom (15)")

        let catNoCount = Category(key: CategoryKey(rawValue: "life"), displayName: "Life", quoteCount: nil)
        XCTAssertEqual(homeView.categoryTitle(for: catNoCount), "Life")

        XCTAssertEqual(homeView.clampedDepth(5, for: nil), 5)
        XCTAssertEqual(homeView.clampedDepth(-2, for: nil), 0)

        // cropImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        let wideImg = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
        }
        let croppedToSquare = homeView.cropImage(wideImg, toAspect: 1.0)
        XCTAssertGreaterThan(croppedToSquare.size.width, 0)

        let tallRenderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 400))
        let tallImg = tallRenderer.image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 400))
        }
        let croppedTallToSquare = homeView.cropImage(tallImg, toAspect: 1.0)
        XCTAssertGreaterThan(croppedTallToSquare.size.width, 0)

        let noCrop = homeView.cropImage(wideImg, toAspect: 2.0)
        XCTAssertEqual(noCrop.size.width, wideImg.size.width)

        let invalidAspect = homeView.cropImage(wideImg, toAspect: -1.0)
        XCTAssertEqual(invalidAspect.size.width, wideImg.size.width)

        // adaptContent
        let sampleQuote = Quote(id: "h-q", text: "T", author: "A", source: .zenQuotes, categoryKey: nil)
        let content = FeedPageViewModel.FeedPageContent(
            quote: sampleQuote,
            image: wideImg,
            originalImage: wideImg,
            imageURL: URL(string: "https://example.com/h.jpg")!,
            imageSource: .picsum,
            seed: "1",
            imageCategoryTitle: nil
        )
        let adapted = homeView.adaptContent(content, for: .fullScreen)
        XCTAssertNotNil(adapted.image)

        let adaptedCropped = homeView.adaptContent(content, for: .oneToOne)
        XCTAssertNotNil(adaptedCropped.image)
    }
}
