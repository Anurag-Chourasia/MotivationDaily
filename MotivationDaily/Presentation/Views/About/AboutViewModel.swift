import Foundation
import Combine

final class AboutViewModel: ObservableObject {
    struct SocialLink: Identifiable {
        let title: String
        let image: String
        let url: URL

        var id: String { title }
    }

    let navigationTitle = "About Developer"
    let developerName = "Anurag Chourasia"
    let developerRole = "iOS Developer"
    let appName = "MotivationDaily"
    let appDescription = "Built with SwiftUI, Clean Architecture and MVVM."
    let disclaimer = "Quotes and wallpapers are provided by public APIs and may vary."

    @Published var showInvalidLinkAlert = false

    let socialLinks: [SocialLink] = AboutViewModel.buildSocialLinks()

    var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private static func buildSocialLinks() -> [SocialLink] {
        [
            makeSocialLink(
                title: "GitHub",
                image: "GitHub",
                urlString: "https://github.com/Anurag-Chourasia"
            ),
            makeSocialLink(
                title: "LinkedIn",
                image: "LinkedIn",
                urlString: "https://www.linkedin.com/in/anurag-chourasia-b66710178/"
            ),
            makeSocialLink(
                title: "Email",
                image: "Gmail",
                urlString: "mailto:anuragchourasiaios@gmail.com"
            ),
            makeSocialLink(
                title: "CV",
                image: "CV",
                urlString: "https://drive.google.com/file/d/16lYgU9C3WyBlL1Jzf__tKiaXxnsNZ_jd/view"
            )
        ]
        .compactMap { $0 }
    }

    private static func makeSocialLink(
        title: String,
        image: String,
        urlString: String
    ) -> SocialLink? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        return SocialLink(title: title, image: image, url: url)
    }
}
