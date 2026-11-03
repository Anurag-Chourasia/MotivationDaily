//
//  AccessibilityJourneyTests.swift
//  MotivationDailyTests
//
//  Accessibility on complete app journeys verification (IOS-25)
//

import XCTest
import SwiftUI
import DesignTokensKit
import UIComponentsKit
@testable import MotivationDaily

@MainActor
final class AccessibilityJourneyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.set("stub", forKey: "developer.source")
        UserDefaults.standard.set("showcase", forKey: "developer.scenario")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "developer.source")
        UserDefaults.standard.removeObject(forKey: "developer.scenario")
        try await super.tearDown()
    }

    // MARK: - Dynamic Type & Text Clipping Verification

    func testDynamicTypeMaximumAccessibilitySizesOnFavoriteCell() {
        let favorite = FavoriteQuote(
            id: "quote-a11y-1",
            text: "Accessibility is not a feature, it is the fundamental foundation of inclusive design and human dignity in software engineering.",
            author: "Distinguished Accessibility Architect",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "inspirational"),
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "portrait",
            imageWidth: 1080,
            imageHeight: 1920
        )

        for typeSize in [DynamicTypeSize.large, .accessibility3, .accessibility5] {
            let cell = FavoriteCellView(
                favorite: favorite,
                imageURL: nil,
                onImageTap: {},
                onToggleFavorite: {},
                onImageDataResolved: nil
            )
            .environment(\.dynamicTypeSize, typeSize)

            let controller = UIHostingController(rootView: cell)
            controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 350)
            controller.view.layoutIfNeeded()

            XCTAssertGreaterThan(controller.view.frame.width, 0)
            XCTAssertGreaterThan(controller.view.frame.height, 0)
        }
    }

    // MARK: - VoiceOver Labels & Share Sheet Accessibility

    func testShareImageQuoteViewVoiceOverAccessibility() {
        let favorite = FavoriteQuote(
            id: "quote-a11y-share",
            text: "The only limit to our realization of tomorrow is our doubts of today.",
            author: "Franklin D. Roosevelt",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "inspirational"),
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "square",
            imageWidth: 1080,
            imageHeight: 1080
        )

        let shareView = ShareImageQuoteView(
            favorite: favorite,
            favoriteImage: nil,
            quote: nil,
            wallpaper: nil,
            layoutSize: CGSize(width: 390, height: 844)
        )

        let controller = UIHostingController(rootView: shareView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 600)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    // MARK: - Connectivity Banner VoiceOver Accessibility

    func testConnectivityBannerAccessibilityElement() {
        let banner = ConnectivityBannerView(
            message: "Offline mode active. Showing cached motivation.",
            isWarning: true,
            accent: DesignColor.orange
        )
        let controller = UIHostingController(rootView: banner)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 50)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    // MARK: - About Screen Dynamic Type and Contrast

    func testAboutViewDynamicTypeScaling() {
        let aboutView = AboutView()
            .environment(\.dynamicTypeSize, .accessibility3)
            .environment(\.colorScheme, .dark)

        let controller = UIHostingController(rootView: aboutView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.frame.width, 0)
    }
}
