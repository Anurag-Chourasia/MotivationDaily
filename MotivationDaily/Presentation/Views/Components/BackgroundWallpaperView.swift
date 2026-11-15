import SwiftUI
import UIKit
import DesignTokensKit

struct BackgroundWallpaperView: View {
    let url: URL?
    let aspectRatio: CGFloat?
    let imageLoader: any ImageLoading
    let onImageLoaded: ((UIImage, URL) -> Void)?
    let onImageFailed: ((URL) -> Void)?

    @State var currentImage: UIImage?
    @State var nextImage: UIImage?
    @State var isLoading = false
    @State var loadTask: Task<Void, Never>?
    @State var activeURL: URL?
    @State var displayedURL: URL?

    init(
        url: URL?,
        aspectRatio: CGFloat? = 9.0 / 16.0,
        imageLoader: any ImageLoading = ImageLoader.shared,
        onImageLoaded: ((UIImage, URL) -> Void)? = nil,
        onImageFailed: ((URL) -> Void)? = nil
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.imageLoader = imageLoader
        self.onImageLoaded = onImageLoaded
        self.onImageFailed = onImageFailed
    }

    var body: some View {
        GeometryReader { proxy in
            let frame = fittedImageFrame(in: proxy.size)
            ZStack {
                Rectangle().fill(\.black).frame(maxWidth: .infinity, maxHeight: .infinity)
                ZStack {
                    BackgroundWallpaperLayer(image: currentImage, frame: frame)
                    if let nextImage { BackgroundWallpaperLayer(image: nextImage, frame: frame) }
                }
                .frame(width: frame.width, height: frame.height).clipped()
                if isLoading, currentImage == nil {
                    ProgressView().progressViewStyle(.circular).tint(\.white, opacity: \.p0_8)
                        .scaleEffect(ScaleToken.p1_15).padding(\.twelve)
                        .background(\.black, opacity: \.p0_25).clipShape(Circle()).opacity(\.p0_6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: url) { loadImage(from: $0) }
        .onAppear { loadImage(from: url) }
        .onDisappear { loadTask?.cancel() }
    }
}
