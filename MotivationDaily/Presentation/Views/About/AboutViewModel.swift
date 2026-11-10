import Foundation
import Combine
import DeveloperProfileKit
import LocalizationKit
import FoundationKit

final class AboutViewModel: ObservableObject {
    var navigationTitle: String { MotivationStrings(provider: localization).aboutDeveloper }
    let developerName = "Anurag Chourasia"
    var developerRole: String { MotivationStrings(provider: localization).developerRole }
    var appName: String { MotivationStrings(provider: localization).motivationAppName }
    var appDescription: String { MotivationStrings(provider: localization).appDescription }
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
        labels.okay = CommonStrings(provider: localization).ok
        return labels
    }
}
