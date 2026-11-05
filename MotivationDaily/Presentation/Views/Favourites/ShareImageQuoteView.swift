import SwiftUI
import UIComponentsKit
import UIKit
import Photos
import DesignTokensKit
import LocalizationKit

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

struct ShareImageQuoteView: View {
    let favorite: FavoriteQuote?
    let favoriteImage: UIImage?
    let quote: Quote?
    let wallpaper: UIImage?
    let layoutSize: CGSize?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.motivationL10n) private var l10n
    @State private var showCopiedBadge = false
    @State private var showCopiedAlert = false
    @State private var compositeImage: UIImage?
    @State private var sourceImage: UIImage?
    @State private var activeSharePayload: SharePayload?
    @State private var isPreparingImage = false
    @State private var imageLoadTask: Task<Void, Never>?
    @State private var isSavingImage = false
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

    @State private var activeSaveAlert: SaveAlert?
    @State private var showPermissionSettingsDialog = false
    @State private var showSaveOptionsDialog = false
    @State private var quoteOnlyImage: UIImage?

    init(
        favorite: FavoriteQuote?,
        favoriteImage: UIImage?,
        quote: Quote?,
        wallpaper: UIImage?,
        layoutSize: CGSize? = nil
    ) {
        self.favorite = favorite
        self.favoriteImage = favoriteImage
        self.quote = quote
        self.wallpaper = wallpaper
        self.layoutSize = layoutSize
    }

    private var shareContent: String {
        let content = favorite?.text ?? quote?.text ?? ""
        let author = favorite?.author ?? quote?.author ?? ""
        return "✨ \"\(content)\"\n\n— \(author)\n\n#DailyMotivation"
    }

    private var quoteText: String {
        favorite?.text ?? quote?.text ?? ""
    }

    private var quoteAuthor: String {
        favorite?.author ?? quote?.author ?? String(\MotivationStrings.authorUnknown)
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Text(\.share)
                .font(\.headline)

            Spacer()

            Button(\.done) {
                dismiss()
            }
            .accessibilityIdentifier(.shareDoneButton)
        }
        .padding(\.sixteen)
    }

    @ViewBuilder
    private var previewContent: some View {
        if let compositeImage {
            Image(uiImage: compositeImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: \.p300)
                .cornerRadius(\.twelve)

            Text(\.previewShareTitle)
                .font(\.caption)
                .foregroundColor(\.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, \.sixteen)
        } else if isPreparingImage {
            HStack(spacing: \.ten) {
                ProgressView()
                Text(\.preparingImage)
                    .font(\.caption)
                    .foregroundColor(\.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, \.sixteen)
        }
    }

    var body: some View {
        VStack(spacing: \.twenty) {
            headerBar

            ScrollView {
                VStack(spacing: \.sixteen) {
                    previewContent
                    actionButtonsList
                        .padding(\.sixteen)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(.shareSheet)
        .onAppear(perform: createShareableImage)
        .onDisappear {
            imageLoadTask?.cancel()
        }
        .sheet(item: $activeSharePayload) { payload in
            ActivityShareSheet(activityItems: payload.items)
        }
        .alert(\.copied, isPresented: $showCopiedAlert) {
            Button(\.ok) {}
        } message: {
            Text(\.quoteCopiedToast)
        }
        .alert(item: $activeSaveAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(\.ok)
            )
        }
        .confirmationDialog(\.photosAccessAlertTitle, isPresented: $showPermissionSettingsDialog, titleVisibility: .visible) {
            Button(\.openSettings) {
                openAppSettings()
            }
            Button(\.cancel, role: .cancel) {}
        } message: {
            Text(\.photosAccessAlertMessage)
        }
        .confirmationDialog(\.saveToPhotos, isPresented: $showSaveOptionsDialog, titleVisibility: .visible) {
            if let quoteOnlyImage {
                Button(\.saveQuoteGradient) {
                    Task {
                        await saveImageToPhotos(quoteOnlyImage)
                    }
                }
            }
            if let sourceImage {
                Button(\.saveOnlyImage) {
                    Task {
                        await saveImageToPhotos(sourceImage)
                    }
                }
            }
            if let compositeImage {
                Button(\.saveImagePlusQuote) {
                    Task {
                        await saveImageToPhotos(compositeImage)
                    }
                }
            }
            Button(\.cancel, role: .cancel) {}
        }
    }

    @ViewBuilder
    private var actionButtonsList: some View {
        VStack(spacing: \.twelve) {
            Button(action: {
                guard let compositeImage else { return }
                openShare(items: [compositeImage])
            }) {
                shareButtonContent(
                    \.photoBadgeCheckmarkFill,
                    title: \.shareQuoteAndImage,
                    subtitle: \.quoteEmbeddedInImage,
                    themeColor: \.blue
                )
            }
            .disabled(compositeImage == nil)
            .opacity(compositeImage == nil ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareQuoteAndImageButton)

            Button(action: {
                guard let sourceImage else { return }
                openShare(items: [sourceImage])
            }) {
                shareButtonContent(
                    \.photoFill,
                    title: \.shareImageOnly,
                    subtitle: \.wallpaperBackgroundOnly,
                    themeColor: \.turquoise
                )
            }
            .disabled(sourceImage == nil)
            .opacity(sourceImage == nil ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareImageOnlyButton)

            Button(action: {
                showSaveOptionsDialog = true
            }) {
                saveToPhotosButtonContent
            }
            .disabled((sourceImage == nil && compositeImage == nil && quoteOnlyImage == nil) || isSavingImage)
            .opacity(((sourceImage == nil && compositeImage == nil && quoteOnlyImage == nil) || isSavingImage) ? \.p0_55 : \.p1_0)
            .accessibilityIdentifier(.shareSaveToPhotosButton)

            Button(action: {
                openShare(items: [shareContent])
            }) {
                shareButtonContent(
                    \.quoteOpening,
                    title: \.shareQuoteOnly,
                    subtitle: \.blackGradientBackground,
                    themeColor: \.green
                )
            }
            .accessibilityIdentifier(.shareQuoteOnlyButton)

            Button(action: copyToClipboard) {
                copyQuoteButtonContent
            }
            .accessibilityIdentifier(.shareCopyQuoteButton)
        }
    }

    private var saveToPhotosButtonContent: some View {
        HStack(spacing: \.ten) {
            Image(\.squareAndArrowDown)
                .font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(isSavingImage ? \.preparingImage : \.saveToPhotos)
                    .fontWeight(.semibold)
                    .font(\.body)
                Text(\.chooseWhatToSave)
                    .font(\.caption)
                    .foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
            if isSavingImage {
                ProgressView()
                    .tint(\.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [
                    ThemeColorStop(\.oceanAction, opacity: \.p0_85),
                    ThemeColorStop(\.oceanAction)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(\.white)
        .cornerRadius(\.twelve)
    }

    private var copyQuoteButtonContent: some View {
        HStack(spacing: \.ten) {
            Image(\.docOnDocFill)
                .font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(\.copyQuote)
                    .fontWeight(.semibold)
                    .font(\.body)
                Text(\.pasteAnywhere)
                    .font(\.caption)
                    .foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
            if showCopiedBadge {
                Image(\.checkmarkCircleFill)
                    .foregroundColor(\.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [
                    ThemeColorStop(\.orange, opacity: \.p0_8),
                    ThemeColorStop(\.orange)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(\.white)
        .cornerRadius(\.twelve)
    }

    private func shareButtonContent(
        _ symbol: KeyPath<SymbolTheme, AppSymbol>,
        title: KeyPath<MotivationStrings, String>,
        subtitle: KeyPath<MotivationStrings, String>,
        themeColor: KeyPath<ColorTheme, Color>
    ) -> some View {
        HStack(spacing: \.ten) {
            Image(symbol)
                .font(\.title3)
            VStack(alignment: .leading, spacing: \.two) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(\.body)
                Text(subtitle)
                    .font(\.caption)
                    .foregroundColor(\.white, opacity: \.p0_7)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(\.fourteen)
        .background(
            LinearGradient(
                stops: [
                    ThemeColorStop(themeColor, opacity: \.p0_8),
                    ThemeColorStop(themeColor)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(\.white)
        .cornerRadius(\.twelve)
    }

    private func openShare(items: [Any]) {
        activeSharePayload = SharePayload(items: items)
    }

    private func createShareableImage() {
        imageLoadTask?.cancel()
        let screenSize = UIScreen.main.bounds.size
        let quoteOnlySize = preferredLayoutSize() ?? screenSize
        sourceImage = nil
        compositeImage = nil
        quoteOnlyImage = nil
        isPreparingImage = false
        renderQuoteOnly(size: quoteOnlySize)

        if let favorite {
            if let favoriteImage {
                sourceImage = favoriteImage
                renderComposite(
                    image: favoriteImage,
                    content: quoteText,
                    author: quoteAuthor
                )
                return
            }

            if let localURL = favorite.resolvedLocalImageURL,
               let localImage = UIImage(contentsOfFile: localURL.path) {
                sourceImage = localImage
                renderComposite(
                    image: localImage,
                    content: quoteText,
                    author: quoteAuthor
                )
                return
            }

            if let imageURL = favorite.imageURL {
                if let cached = LightImageCache.shared.image(for: imageURL) {
                    sourceImage = cached
                    renderComposite(
                        image: cached,
                        content: quoteText,
                        author: quoteAuthor
                    )
                    return
                }

                isPreparingImage = true
                imageLoadTask = Task {
                    let cachedOnlyImage = await ImageLoader.shared.cachedImage(for: imageURL)
                    if Task.isCancelled { return }
                    await MainActor.run {
                        if let cachedOnlyImage {
                            sourceImage = cachedOnlyImage
                            renderComposite(
                                image: cachedOnlyImage,
                                content: quoteText,
                                author: quoteAuthor
                            )
                        }
                        isPreparingImage = false
                    }
                }
                return
            }
        }

        if let wallpaper {
            sourceImage = wallpaper
            renderComposite(
                image: wallpaper,
                content: quoteText,
                author: quoteAuthor
            )
            return
        }

        isPreparingImage = false
    }

    private func renderComposite(
        image: UIImage,
        content: String,
        author: String
    ) {
        compositeImage = composeQuoteImageWithRetry(
            source: image,
            content: content,
            author: author,
            layoutSize: resolvedLayoutSize(for: image)
        )
    }

    private func renderQuoteOnly(size: CGSize) {
        quoteOnlyImage = composeQuoteOnlyWithRetry(size: size)
    }

    private func composeQuoteImageWithRetry(
        source: UIImage,
        content: String,
        author: String,
        layoutSize: CGSize?
    ) -> UIImage? {
        let first = QuoteImageComposer.composeQuoteImage(
            source: source,
            quoteText: content,
            author: author,
            layoutSize: layoutSize
        )
        if !isLikelyBlank(first) {
            return first
        }

        let second = QuoteImageComposer.composeQuoteImage(
            source: source,
            quoteText: content,
            author: author,
            layoutSize: layoutSize
        )
        if !isLikelyBlank(second) {
            return second
        }

        presentSnapshotFailureAlert()
        return nil
    }

    private func composeQuoteOnlyWithRetry(size: CGSize) -> UIImage? {
        let first = QuoteImageComposer.composeQuoteOnlyImage(
            quoteText: quoteText,
            author: quoteAuthor,
            size: size
        )
        if !isLikelyBlank(first) {
            return first
        }

        let second = QuoteImageComposer.composeQuoteOnlyImage(
            quoteText: quoteText,
            author: quoteAuthor,
            size: size
        )
        if !isLikelyBlank(second) {
            return second
        }

        presentSnapshotFailureAlert()
        return nil
    }

    private func resolvedLayoutSize(for image: UIImage) -> CGSize? {
        if let preferred = preferredLayoutSize() {
            return preferred
        }

        if image.size.width > 0, image.size.height > 0 {
            return image.size
        }

        return nil
    }

    func preferredLayoutSize() -> CGSize? {
        if let layoutSize, layoutSize.width > 0, layoutSize.height > 0 {
            return layoutSize
        }

        if let favorite,
           let width = favorite.imageWidth,
           let height = favorite.imageHeight,
           width > 0,
           height > 0 {
            let scale = max(UIScreen.main.scale, 1)
            return CGSize(width: CGFloat(width) / scale, height: CGFloat(height) / scale)
        }

        return nil
    }

    func copyToClipboard() {
        UIPasteboard.general.string = shareContent
        showCopiedBadge = true
        showCopiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedBadge = false
        }
    }

    func presentSnapshotFailureAlert() {
        activeSaveAlert = .snapshotFailure
    }

    func isLikelyBlank(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return true }
        let width = 8
        let height = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return true
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hasOpaquePixel = false
        var hasNonWhitePixel = false
        for i in stride(from: 0, to: data.count, by: 4) {
            let r = data[i]
            let g = data[i + 1]
            let b = data[i + 2]
            let a = data[i + 3]
            if a > 10 {
                hasOpaquePixel = true
                if r < 245 || g < 245 || b < 245 {
                    hasNonWhitePixel = true
                    break
                }
            }
        }
        if !hasOpaquePixel {
            return true
        }
        return !hasNonWhitePixel
    }

    private func saveImageToPhotos(_ image: UIImage) async {
        await MainActor.run {
            isSavingImage = true
        }

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
                isSavingImage = false
                activeSaveAlert = .saved
            }
        } catch {
            await MainActor.run {
                isSavingImage = false
                activeSaveAlert = .saveFailed
            }
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
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
                            domain: "ShareImageQuoteView",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Unknown save error."]
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    ShareImageQuoteView(favorite: nil, favoriteImage: nil, quote: nil, wallpaper: nil)
}
