import SwiftUI
import UIComponentsKit
import UIKit
import DesignTokensKit
import LocalizationKit

struct ShareImageQuoteView: View {
    let favorite: FavoriteQuote?
    let favoriteImage: UIImage?
    let quote: Quote?
    let wallpaper: UIImage?
    let layoutSize: CGSize?
    var imageLoader: any ImageLoading = ImageLoader.shared

    @Environment(\.dismiss) private var dismiss
    @State var showCopiedBadge = false
    @State var showCopiedAlert = false
    @State var compositeImage: UIImage?
    @State var sourceImage: UIImage?
    @State var activeSharePayload: SharePayload?
    @State var isPreparingImage = false
    @State var imageLoadTask: Task<Void, Never>?
    @State var isSavingImage = false
    @State var activeSaveAlert: SaveAlert?
    @State var showPermissionSettingsDialog = false
    @State var showSaveOptionsDialog = false
    @State var quoteOnlyImage: UIImage?

    init(
        favorite: FavoriteQuote?, favoriteImage: UIImage?, quote: Quote?,
        wallpaper: UIImage?, layoutSize: CGSize? = nil, imageLoader: (any ImageLoading)? = nil
    ) {
        self.favorite = favorite; self.favoriteImage = favoriteImage
        self.quote = quote; self.wallpaper = wallpaper; self.layoutSize = layoutSize
        if let imageLoader { self.imageLoader = imageLoader }
    }

    var body: some View {
        VStack(spacing: \.twenty) {
            ShareHeaderBarView { dismiss() }
            ScrollView {
                VStack(spacing: \.sixteen) {
                    SharePreviewContentView(compositeImage: compositeImage, isPreparingImage: isPreparingImage)
                    actionButtons
                        .padding(\.sixteen)
                }
            }
        }
        .accessibilityElement(children: .contain).accessibilityIdentifier(.shareSheet)
        .task { await createShareableImage() }
        .onDisappear { imageLoadTask?.cancel() }
        .sheet(item: $activeSharePayload) { ActivityShareSheet(activityItems: $0.items) }
        .alert(\.copied, isPresented: $showCopiedAlert) {
            Button(\.ok) {}
        } message: { Text(\.quoteCopiedToast) }
        .alert(item: $activeSaveAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(\.ok))
        }
        .confirmationDialog(\.photosAccessAlertTitle, isPresented: $showPermissionSettingsDialog, titleVisibility: .visible) {
            Button(\.openSettings) { openAppSettings() }
            Button(\.cancel, role: .cancel) {}
        } message: { Text(\.photosAccessAlertMessage) }
        .confirmationDialog(\.saveToPhotos, isPresented: $showSaveOptionsDialog, titleVisibility: .visible) {
            if let quoteOnlyImage { Button(\.saveQuoteGradient) { saveImageTask(quoteOnlyImage) } }
            if let sourceImage { Button(\.saveOnlyImage) { saveImageTask(sourceImage) } }
            if let compositeImage { Button(\.saveImagePlusQuote) { saveImageTask(compositeImage) } }
            Button(\.cancel, role: .cancel) {}
        }
    }

    private var actionButtons: some View {
        ShareActionButtonsList(
            compositeImage: compositeImage, sourceImage: sourceImage, quoteOnlyImage: quoteOnlyImage,
            isSavingImage: isSavingImage, showCopiedBadge: showCopiedBadge,
            onShareComposite: shareCompositeAction,
            onShareSource: shareSourceAction,
            onOpenSaveOptions: openSaveOptionsAction,
            onShareQuoteOnly: shareQuoteOnlyAction,
            onCopyQuote: copyToClipboard
        )
    }

    func openShare(items: [Any]) { activeSharePayload = SharePayload(items: items) }
    func shareCompositeAction() { if let compositeImage { openShare(items: [compositeImage]) } }
    func shareSourceAction() { if let sourceImage { openShare(items: [sourceImage]) } }
    func openSaveOptionsAction() { showSaveOptionsDialog = true }
    func shareQuoteOnlyAction() { openShare(items: [shareContent]) }
    func saveImageTask(_ img: UIImage) { Task { await saveImageToPhotos(img) } }
}
