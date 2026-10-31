import SwiftUI
import UIKit
import Photos

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
    @State private var showCopiedAlert = false
    @State private var compositeImage: UIImage?
    @State private var sourceImage: UIImage?
    @State private var activeSharePayload: SharePayload?
    @State private var isPreparingImage = false
    @State private var imageLoadTask: Task<Void, Never>?
    @State private var isSavingImage = false
    @State private var showSaveAlert = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
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
        favorite?.author ?? quote?.author ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Share")
                    .font(.headline)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .accessibilityIdentifier("share.doneButton")
            }
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    if let compositeImage {
                        Image(uiImage: compositeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)

                        Text("Preview - This is what will be shared")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    } else if isPreparingImage {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Preparing image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Button(action: {
                            guard let compositeImage else { return }
                            openShare(items: [compositeImage])
                        }) {
                            shareButtonContent(
                                icon: "photo.badge.checkmark.fill",
                                title: "Share Quote + Image",
                                subtitle: "Quote embedded in image",
                                colors: [Color.blue.opacity(0.8), .blue]
                            )
                        }
                        .disabled(compositeImage == nil)
                        .opacity(compositeImage == nil ? 0.55 : 1.0)
                        .accessibilityIdentifier("share.quoteAndImageButton")

                        Button(action: {
                            guard let sourceImage else { return }
                            openShare(items: [sourceImage])
                        }) {
                            shareButtonContent(
                                icon: "photo.fill",
                                title: "Share Only Image",
                                subtitle: "Wallpaper image only",
                                colors: [Color.purple.opacity(0.8), .purple]
                            )
                        }
                        .disabled(sourceImage == nil)
                        .opacity(sourceImage == nil ? 0.55 : 1.0)
                        .accessibilityIdentifier("share.imageOnlyButton")

                        Button(action: {
                            showSaveOptionsDialog = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isSavingImage ? "Saving..." : "Save to Photos")
                                        .fontWeight(.semibold)
                                        .font(.body)
                                    Text("Choose what to save")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                if isSavingImage {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [Color.indigo.opacity(0.85), .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled((sourceImage == nil && compositeImage == nil && quoteOnlyImage == nil) || isSavingImage)
                        .opacity(((sourceImage == nil && compositeImage == nil && quoteOnlyImage == nil) || isSavingImage) ? 0.55 : 1.0)
                        .accessibilityIdentifier("share.saveToPhotosButton")

                        Button(action: {
                            openShare(items: [shareContent])
                        }) {
                            shareButtonContent(
                                icon: "text.quote.fill",
                                title: "Share Only Quote",
                                subtitle: "Text only, no image",
                                colors: [Color.green.opacity(0.8), .green]
                            )
                        }
                        .accessibilityIdentifier("share.quoteOnlyButton")

                        Button(action: copyToClipboard) {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Copy Quote")
                                        .fontWeight(.semibold)
                                        .font(.body)
                                    Text("Paste anywhere")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                if showCopiedAlert {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.8), .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .accessibilityIdentifier("share.copyQuoteButton")
                    }
                    .padding()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("share.sheet")
        .onAppear(perform: createShareableImage)
        .onDisappear {
            imageLoadTask?.cancel()
        }
        .sheet(item: $activeSharePayload) { payload in
            ActivityShareSheet(activityItems: payload.items)
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK") {}
        } message: {
            Text("Quote copied to clipboard")
        }
        .alert(saveAlertTitle, isPresented: $showSaveAlert) {
            Button("OK") {}
        } message: {
            Text(saveAlertMessage)
        }
        .confirmationDialog("Photo Access Needed", isPresented: $showPermissionSettingsDialog, titleVisibility: .visible) {
            Button("Open Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Photos access in Settings to save wallpapers.")
        }
        .confirmationDialog("Save to Photos", isPresented: $showSaveOptionsDialog, titleVisibility: .visible) {
            if let quoteOnlyImage {
                Button("Save Quote (Black Gradient)") {
                    Task {
                        await saveImageToPhotos(quoteOnlyImage)
                    }
                }
            }
            if let sourceImage {
                Button("Save Only Image") {
                    Task {
                        await saveImageToPhotos(sourceImage)
                    }
                }
            }
            if let compositeImage {
                Button("Save Image + Quote") {
                    Task {
                        await saveImageToPhotos(compositeImage)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func shareButtonContent(
        icon: String,
        title: String,
        subtitle: String,
        colors: [Color]
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        )
        .foregroundColor(.white)
        .cornerRadius(12)
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
        showCopiedAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedAlert = false
        }
    }

    func presentSnapshotFailureAlert() {
        saveAlertTitle = "Share Image Failed"
        saveAlertMessage = "We couldn't prepare the share image. Please try again."
        showSaveAlert = true
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
                    saveAlertTitle = "Permission Required"
                    saveAlertMessage = "Allow photo access to save images."
                    showSaveAlert = true
                }
            }
            return
        }

        do {
            try await writeImageToPhotoLibrary(image)
            await MainActor.run {
                isSavingImage = false
                saveAlertTitle = "Saved"
                saveAlertMessage = "Image saved to Photos."
                showSaveAlert = true
            }
        } catch {
            await MainActor.run {
                isSavingImage = false
                saveAlertTitle = "Save Failed"
                saveAlertMessage = "Could not save image. Please try again."
                showSaveAlert = true
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
