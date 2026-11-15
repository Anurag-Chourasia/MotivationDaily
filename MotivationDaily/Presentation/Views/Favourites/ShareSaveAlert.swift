import SwiftUI
import LocalizationKit

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

enum SaveAlert: Identifiable {
    case snapshotFailure
    case permissionRequired
    case saved
    case saveFailed

    var id: Self { self }

    var title: KeyPath<MotivationStrings, String> {
        switch self {
        case .snapshotFailure: return \.shareImageFailed
        case .permissionRequired: return \.permissionRequired
        case .saved: return \.saved
        case .saveFailed: return \.saveFailed
        }
    }

    var message: KeyPath<MotivationStrings, String> {
        switch self {
        case .snapshotFailure: return \.shareImageFailedMessage
        case .permissionRequired: return \.permissionRequiredPhotosMessage
        case .saved: return \.imageSavedToPhotos
        case .saveFailed: return \.couldNotSaveImage
        }
    }
}
