import SwiftUI
import UIKit

struct BackgroundWallpaperView: View {
    let url: URL?
    let aspectRatio: CGFloat?
    let onImageLoaded: ((UIImage, URL) -> Void)?
    let onImageFailed: ((URL) -> Void)?

    @State private var currentImage: UIImage?
    @State private var nextImage: UIImage?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?
    @State private var activeURL: URL?
    @State private var displayedURL: URL?

    init(
        url: URL?,
        aspectRatio: CGFloat? = 9.0 / 16.0,
        onImageLoaded: ((UIImage, URL) -> Void)? = nil,
        onImageFailed: ((URL) -> Void)? = nil
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.onImageLoaded = onImageLoaded
        self.onImageFailed = onImageFailed
    }

    var body: some View {
        GeometryReader { proxy in
            let imageFrame = fittedImageFrame(in: proxy.size)

            ZStack {
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ZStack {
                    backgroundLayer(image: currentImage, frame: imageFrame)

                    if let nextImage {
                        backgroundLayer(image: nextImage, frame: imageFrame)
                    }
                }
                .frame(width: imageFrame.width, height: imageFrame.height)
                .clipped()

                if isLoading, currentImage == nil {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white.opacity(0.8))
                        .scaleEffect(1.1)
                        .padding(12)
                        .background(Color.black.opacity(0.25))
                        .clipShape(Circle())
                        .opacity(0.6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: url) { newValue in
            loadImage(from: newValue)
        }
        .onAppear {
            loadImage(from: url)
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private func backgroundLayer(image: UIImage?, frame: CGSize) -> some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame.width, height: frame.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.88),
                        Color(red: 0.08, green: 0.08, blue: 0.1),
                        Color.black.opacity(0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: frame.width, height: frame.height)
            }
        }
    }

    private func fittedImageFrame(in container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        guard let aspectRatio, aspectRatio > 0 else { return container }
        let width = container.width
        return CGSize(width: width, height: width / aspectRatio)
    }

    private func loadImage(from url: URL?) {
        guard displayedURL != url || currentImage == nil else { return }
        if activeURL == url, isLoading {
            return
        }
        loadTask?.cancel()
        activeURL = url

        guard let url else {
            currentImage = nil
            nextImage = nil
            isLoading = false
            displayedURL = nil
            return
        }

        if let cached = LightImageCache.shared.image(for: url) {
            guard activeURL == url else { return }
            currentImage = cached
            nextImage = nil
            isLoading = false
            displayedURL = url
            onImageLoaded?(cached, url)
            return
        }

        isLoading = true
        loadTask = Task {
            do {
                let image = try await ImageLoader.shared.load(url: url)
                if Task.isCancelled { return }
                await MainActor.run {
                    guard activeURL == url else { return }
                    nextImage = image
                    currentImage = nextImage
                    nextImage = nil
                    isLoading = false
                    displayedURL = url
                    onImageLoaded?(image, url)
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    guard activeURL == url else { return }
                    nextImage = nil
                    isLoading = false
                    onImageFailed?(url)
                }
            }
        }
    }
}

#Preview {
    BackgroundWallpaperView(url: nil)
}
