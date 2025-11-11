import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let favorite: FavoriteQuote?
    let favoriteImage: UIImage?
    @Binding var isPresented: Bool
    let onImageDataResolved: ((String, Data) -> Void)?

    @State private var showShareSheet = false
    @State private var displayedImage: UIImage?
    @State private var isLoadingImage = false
    @State private var loadTask: Task<Void, Never>?
    @State private var selectedRatio: WallpaperAspectRatio = .fullScreen

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = fullScreenCanvasSize(for: proxy)
            ZStack {
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                if let displayedImage {
                    let imageRect = imageRect(for: displayedImage, in: canvasSize, ratio: selectedRatio)
                    fullScreenImageView(for: displayedImage, in: imageRect, canvasSize: canvasSize)
                } else if isLoadingImage {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.2)
                        .tint(.white)
                } else {
                    emptyImage
                }
                
                if let quote = favorite, let displayedImage {
                    let imageRect = imageRect(for: displayedImage, in: canvasSize, ratio: selectedRatio)
                    favoriteQuote(quote, in: imageRect, canvasSize: canvasSize)
                }

                sideActionRail()
                    .padding(.trailing, 16)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 24, 32))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .ignoresSafeArea()
        .onAppear {
            selectedRatio = initialRatio()
            resolveDisplayedImage()
        }
        .onChange(of: favorite?.id) { _ in
            selectedRatio = initialRatio()
            resolveDisplayedImage()
        }
        .onDisappear {
            loadTask?.cancel()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareImageQuoteView(
                favorite: favorite,
                favoriteImage: displayedImage ?? favoriteImage,
                quote: nil,
                wallpaper: nil,
                layoutSize: shareLayoutSize()
            )
        }
    }

    private func fullScreenImageView(for image: UIImage, in imageRect: CGRect, canvasSize: CGSize) -> some View {
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: imageRect.width, height: imageRect.height)
            .frame(width: canvasSize.width, height: canvasSize.height, alignment: .center)
            .clipped()
            .ignoresSafeArea(edges: .all)
    }

    private func sideActionRail() -> some View {
        VStack(spacing: 14) {
            Menu {
                ForEach(WallpaperAspectRatio.allCases) { ratio in
                    Button(action: { selectedRatio = ratio }) {
                        if ratio == selectedRatio {
                            Label(ratio.rawValue, systemImage: "checkmark")
                        } else {
                            Text(ratio.rawValue)
                        }
                    }
                }
            } label: {
                SideActionIconView(
                    systemName: "crop",
                    label: selectedRatio.rawValue,
                    tint: .white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("favorites.fullScreen.ratioButton")

            Button(action: { showShareSheet = true }) {
                SideActionIconView(
                    systemName: "paperplane.fill",
                    label: "Share",
                    tint: .white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("favorites.fullScreen.shareButton")

            Button(action: { isPresented = false }) {
                SideActionIconView(
                    systemName: "xmark",
                    label: "Close",
                    tint: .white
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("favorites.fullScreen.closeButton")
        }
    }

    private func favoriteQuote(_ favorite: FavoriteQuote, in imageRect: CGRect, canvasSize: CGSize) -> some View {
        let style = QuoteCardLayout.style(for: imageRect)
        let quoteCardHeight = resolvedQuoteCardHeight(for: imageRect)
        let quote = Quote(
            id: favorite.id,
            text: favorite.text,
            author: favorite.author,
            source: favorite.source,
            categoryKey: favorite.categoryKey
        )

        return QuoteCardView(
            quote: quote,
            dominantColor: nil,
            overlayOpacity: 0.5,
            compactStyle: style.isCompact,
            showsDepthEffects: true,
            cardHeight: quoteCardHeight
        )
        .frame(width: style.width, height: quoteCardHeight)
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .center)
    }

    private var emptyImage: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Image not available")
                .foregroundColor(.white)
            Spacer()
        }
    }

    private func imageRect(
        for image: UIImage,
        in containerSize: CGSize,
        ratio: WallpaperAspectRatio
    ) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        if ratio == .fullScreen {
            return CGRect(origin: .zero, size: containerSize)
        }

        if let explicitRatio = ratio.value {
            let width = containerSize.width
            let height = width / max(explicitRatio, 0.01)
            let y = (containerSize.height - height) / 2.0
            return CGRect(x: 0, y: y, width: width, height: height)
        }

        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let ratio = imageWidth / imageHeight
        let width = containerSize.width
        let height = width / ratio
        let y = (containerSize.height - height) / 2.0
        return CGRect(x: 0, y: y, width: width, height: height)
    }

    private func minimumQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let style = QuoteCardLayout.style(for: imageRect)
        return style.isCompact ? 160 : 220
    }

    private func preferredQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let style = QuoteCardLayout.style(for: imageRect)
        return style.isCompact ? 248 : 320
    }

    private func resolvedQuoteCardHeight(for imageRect: CGRect) -> CGFloat {
        let availableHeight = max(imageRect.height - 12, 1)
        let minimumHeight = minimumQuoteCardHeight(for: imageRect)
        let preferredHeight = preferredQuoteCardHeight(for: imageRect)
        return min(preferredHeight, max(availableHeight, minimumHeight))
    }

    private func fullScreenCanvasSize(for proxy: GeometryProxy) -> CGSize {
        let width = max(proxy.size.width, UIScreen.main.bounds.width)
        let height = max(
            proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
            UIScreen.main.bounds.height
        )
        return CGSize(width: width, height: height)
    }

    private func resolveDisplayedImage() {
        loadTask?.cancel()
        displayedImage = nil

        if let favoriteImage {
            displayedImage = favoriteImage
            persistImageIfNeeded(favoriteImage)
            return
        }

        if let localPath = favorite?.localImagePath,
           !localPath.isEmpty,
           let localImage = UIImage(contentsOfFile: localPath) {
            displayedImage = localImage
            return
        }

        guard let url = favorite?.imageURL else {
            isLoadingImage = false
            return
        }

        if let cached = LightImageCache.shared.image(for: url) {
            displayedImage = cached
            isLoadingImage = false
            persistImageIfNeeded(cached)
            return
        }

        isLoadingImage = true
        loadTask = Task {
            let cachedOnlyImage = await ImageLoader.shared.cachedImage(for: url)
            if Task.isCancelled { return }
            await MainActor.run {
                if let cachedOnlyImage {
                    displayedImage = cachedOnlyImage
                    persistImageIfNeeded(cachedOnlyImage)
                }
                isLoadingImage = false
            }
        }
    }

    private func persistImageIfNeeded(_ image: UIImage) {
        guard let favorite else { return }
        if let localPath = favorite.localImagePath, !localPath.isEmpty {
            return
        }
        let favoriteID = favorite.id
        let callback = onImageDataResolved
        DispatchQueue.global(qos: .utility).async {
            guard let imageData = image.jpegData(compressionQuality: 0.88) else {
                return
            }
            DispatchQueue.main.async {
                callback?(favoriteID, imageData)
            }
        }
    }

    private func shareLayoutSize() -> CGSize? {
        let scale = max(UIScreen.main.scale, 1)
        if selectedRatio == .fullScreen {
            return UIScreen.main.bounds.size
        }

        if let favorite,
           let width = favorite.imageWidth,
           width > 0 {
            let widthPoints = CGFloat(width) / scale
            if let ratio = selectedRatio.value {
                return CGSize(width: widthPoints, height: widthPoints / max(ratio, 0.01))
            }
            if let height = favorite.imageHeight, height > 0 {
                return CGSize(width: widthPoints, height: CGFloat(height) / scale)
            }
        }

        if let displayedImage {
            if let ratio = selectedRatio.value {
                let width = max(displayedImage.size.width, UIScreen.main.bounds.width)
                return CGSize(width: width, height: width / max(ratio, 0.01))
            }
            return displayedImage.size
        }

        return nil
    }

    private func initialRatio() -> WallpaperAspectRatio {
        guard let raw = favorite?.ratioRawValue else {
            return .fullScreen
        }

        return WallpaperAspectRatio.allCases.first(where: { $0.rawValue == raw }) ?? .fullScreen
    }
}
