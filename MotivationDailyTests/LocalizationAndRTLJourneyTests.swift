//
//  LocalizationAndRTLJourneyTests.swift
//  MotivationDailyTests
//
//  Verification of localized authentication, recoverable errors, and RTL journeys (IOS-26)
//

import XCTest
import SwiftUI
import DesignTokensKit
import UIComponentsKit
import LocalizationKit
import AuthKit
import AuthKitUI
@testable import MotivationDaily

@MainActor
final class LocalizationAndRTLJourneyTests: XCTestCase {

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

    // MARK: - Localized Copy Verification Across Locales

    func testLocalizedAuthAndAccountCopyAcrossLocales() {
        let locales = ["en", "fr", "ar"]

        for localeCode in locales {
            let controller = LocalizationController(initialLocale: Locale(identifier: localeCode))

            let common = CommonStrings(provider: controller)
            let signIn = common.authTitleSignIn
            let email = common.authFieldEmail
            let password = common.authFieldPassword
            let deleteAccount = common.authButtonDeleteAccount
            let signOut = common.authButtonSignOut

            XCTAssertFalse(signIn.isEmpty, "Sign in string should not be empty for \(localeCode)")
            XCTAssertFalse(email.isEmpty, "Email string should not be empty for \(localeCode)")
            XCTAssertFalse(password.isEmpty, "Password string should not be empty for \(localeCode)")
            XCTAssertFalse(deleteAccount.isEmpty, "Delete account should not be empty for \(localeCode)")
            XCTAssertFalse(signOut.isEmpty, "Sign out should not be empty for \(localeCode)")

            if localeCode == "ar" {
                XCTAssertTrue(controller.isRightToLeft, "Arabic locale must be detected as right-to-left")
            } else {
                XCTAssertFalse(controller.isRightToLeft, "\(localeCode) locale must be detected as left-to-right")
            }
        }
    }

    // MARK: - AppAuthGate Integration with LocalizationController and RTL

    func testAppAuthGateWithArabicLocalizationAndRTL() {
        let arabicController = LocalizationController(initialLocale: Locale(identifier: "ar"))
        var signedOut = false

        let gateView = AppAuthGate(
            brand: .motivationDaily,
            localizer: arabicController,
            onSignedOut: { signedOut = true },
            content: { _, _ in
                Text("Authenticated Home Feed")
            }
        )
        .environment(\.layoutDirection, arabicController.isRightToLeft ? .rightToLeft : .leftToRight)

        let gateHost = UIHostingController(rootView: gateView)
        gateHost.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        gateHost.view.layoutIfNeeded()

        XCTAssertNotNil(gateHost.view)
        XCTAssertGreaterThan(gateHost.view.frame.width, 0)
        XCTAssertFalse(signedOut)
    }

    // MARK: - RTL Layout Direction on FavoriteCellView and Dynamic Type

    func testFavoriteCellViewUnderRTL() {
        let favorite = FavoriteQuote(
            id: "ar-quote-1",
            text: "لا تحسبن المجد تمراً أنت آكله لن تبلغ المجد حتى تلعق الصبرا",
            author: "أبو تمام",
            source: .zenQuotes,
            categoryKey: CategoryKey(rawValue: "inspirational"),
            imageURL: nil,
            localImagePath: nil,
            ratioRawValue: "portrait",
            imageWidth: 1080,
            imageHeight: 1920
        )

        let cell = FavoriteCellView(
            favorite: favorite,
            imageURL: nil,
            onImageTap: {},
            onToggleFavorite: {},
            onImageDataResolved: nil
        )
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: cell)
        controller.view.frame = CGRect(x: 0, y: 0, width: 375, height: 350)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.frame.width, 0)
        XCTAssertGreaterThan(controller.view.frame.height, 0)
    }

    // MARK: - Recoverable Connectivity Banner Under RTL

    func testConnectivityBannerUnderRTL() {
        let banner = ConnectivityBannerView(
            message: "أنت في وضع عدم الاتصال حالياً. يتم عرض الاقتباسات المخزنة مؤقتاً.",
            isWarning: true,
            accent: DesignColor.orange
        )
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: banner)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 60)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.frame.width, 0)
    }

    // MARK: - AboutView Under RTL

    func testAboutViewUnderRTL() {
        let aboutView = AboutView()
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: aboutView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertGreaterThan(controller.view.frame.width, 0)
    }
}
