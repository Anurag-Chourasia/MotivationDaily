import SwiftUI
import UIKit
import Photos
import LocalizationKit

extension ShareImageQuoteView {
    func saveImageToPhotos(_ image: UIImage) async {
        await MainActor.run { isSavingImage = true }
        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        let hasPermission: Bool
        switch status {
        case .authorized, .limited:
            hasPermission = true
        case .notDetermined:
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            hasPermission = (status == .authorized || status == .limited)
        default:
            hasPermission = false
        }

        guard hasPermission else {
            await MainActor.run {
                isSavingImage = false
                if status == .denied || status == .restricted {
                    showPermissionSettingsDialog = true
                } else {
                    activeSaveAlert = .permissionRequired
                }
            }
            return
        }

        do {
            try await writeImageToPhotoLibrary(image)
            await MainActor.run {
                isSavingImage = false; activeSaveAlert = .saved
            }
        } catch {
            await MainActor.run {
                isSavingImage = false; activeSaveAlert = .saveFailed
            }
        }
    }

    private func writeImageToPhotoLibrary(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "ShareImageQuoteView", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: String(\MotivationStrings.couldNotSaveImage)]
                        )
                    )
                }
            }
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
