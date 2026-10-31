import Foundation
import Combine
import DeveloperProfileKit
import LocalizationKit
import FoundationKit

final class AboutViewModel: ObservableObject {
    let navigationTitle = "About Developer"
    let developerName = "Anurag Chourasia"
    let developerRole = "iOS Developer"
    let appName = "Motivation Daily"
    let appDescription = "Inspirational quotes paired with aesthetic wallpapers. Built with SwiftUI, Clean Architecture and MVVM."
    let disclaimer = "Quotes and wallpapers are provided by public APIs (Quotable, ZenQuotes, AdviceSlip, and Picsum). All content is owned by their respective authors and creators."

    let version: String
    let build: String
    let localization: LocalizationProviding

    init(
        version: String = AppRuntime.version,
        build: String = AppRuntime.build,
        localization: LocalizationProviding = AppContainer.live.localization
    ) {
        self.version = version
        self.build = build
        self.localization = localization
    }

    var profileLabels: DeveloperProfileLabels {
        var labels = DeveloperProfileLabels()
        labels.appInformation = "App Information"
        labels.version = "Version"
        labels.disclaimer = "Disclaimer"
        labels.social = "Connect"
        labels.readMore = "Read More"
        labels.showLess = "Show Less"
        labels.linkHint = "Double tap to open in browser"
        labels.errorTitle = "Unable to Open Link"
        labels.errorMessage = "Please try again later."
        labels.okay = L10n.Common.ok(using: localization)
        return labels
    }
}
