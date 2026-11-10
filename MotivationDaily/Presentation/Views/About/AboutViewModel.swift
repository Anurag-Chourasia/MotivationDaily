import Foundation
import Combine
import DeveloperProfileKit
import LocalizationKit
import FoundationKit

final class AboutViewModel: ObservableObject {
    var navigationTitle: String { MotivationStrings(provider: localization).aboutDeveloper }
    let developerName = "Anurag Chourasia"
    let developerRole = "iOS Developer"
    var appName: String { MotivationStrings(provider: localization).motivationAppName }
    let appDescription = "Inspirational quotes paired with aesthetic wallpapers. Built with SwiftUI, Clean Architecture and MVVM."
    var disclaimer: String { MotivationStrings(provider: localization).aboutDisclaimer }

    let version: String
    let build: String
    let localization: LocalizationProviding

    init(
        version: String = AppRuntime.version,
        build: String = AppRuntime.build,
        localization: LocalizationProviding = LocalizationController.shared
    ) {
        self.version = version
        self.build = build
        self.localization = localization
    }

    var profileLabels: DeveloperProfileLabels {
        let strings = MotivationStrings(provider: localization)
        var labels = DeveloperProfileLabels()
        labels.appInformation = strings.profileAppInformation
        labels.version = strings.profileVersion
        labels.disclaimer = strings.profileDisclaimer
        labels.social = strings.profileConnect
        labels.readMore = strings.profileReadMore
        labels.showLess = strings.profileShowLess
        labels.linkHint = strings.profileLinkHint
        labels.errorTitle = strings.profileLinkError
        labels.errorMessage = strings.errorRetryLater
        labels.okay = L10n.Common.ok(using: localization)
        return labels
    }
}
