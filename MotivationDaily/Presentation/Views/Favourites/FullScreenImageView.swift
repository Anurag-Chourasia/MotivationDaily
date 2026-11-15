import SwiftUI
import UIComponentsKit
import UIKit
import DesignTokensKit
import LocalizationKit

struct FullScreenImageView: View {
    let favorite: FavoriteQuote?
    let favoriteImage: UIImage?
    var imageLoader: any ImageLoading = ImageLoader.shared
    @Binding var isPresented: Bool
    let onImageDataResolved: ((String, Data) -> Void)?

    @State private var showShareSheet = false
    @State var displayedImage: UIImage?
    @State var isLoadingImage = false
    @State var loadTask: Task<Void, Never>?
    @State var selectedRatio: WallpaperAspectRatio = .fullScreen

    var body: some View {
        GeometryReader { proxy in
            let canvas = FullScreenImageLayoutHelper.fullScreenCanvasSize(for: proxy)
            ZStack {
                Rectangle().fill(\.black).frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
                if let displayedImage {
                    let rect = FullScreenImageLayoutHelper.imageRect(
                        for: displayedImage, in: canvas, ratio: selectedRatio
                    )
                    Image(uiImage: displayedImage)
                        .resizable().scaledToFill()
                        .frame(width: rect.width, height: rect.height)
                        .frame(width: canvas.width, height: canvas.height, alignment: .center)
                        .clipped().ignoresSafeArea(edges: .all)
                    if let quote = favorite {
                        FullScreenQuoteCardOverlay(favorite: quote, imageRect: rect, canvasSize: canvas)
                    }
                } else if isLoadingImage {
                    ProgressView().progressViewStyle(.circular).scaleEffect(ScaleToken.p1_15).tint(\.white)
                } else {
                    emptyImage
                }
                FullScreenActionRailView(
                    selectedRatio: $selectedRatio,
                    onShare: { showShareSheet = true },
                    onClose: { isPresented = false }
                )
                .padding(.trailing, \.sixteen)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + Spacing.twentyFour, Spacing.thirtyTwo))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .ignoresSafeArea()
        .onAppear { selectedRatio = initialRatio(); resolveDisplayedImage() }
        .onChange(of: favorite?.id) { _ in selectedRatio = initialRatio(); resolveDisplayedImage() }
        .onDisappear { loadTask?.cancel() }
        .sheet(isPresented: $showShareSheet) {
            let layoutSize = FullScreenImageLayoutHelper.shareLayoutSize(
                for: favorite, displayedImage: displayedImage, selectedRatio: selectedRatio
            )
            ShareImageQuoteView(
                favorite: favorite,
                favoriteImage: displayedImage ?? favoriteImage,
                quote: nil, wallpaper: nil,
                layoutSize: layoutSize,
                imageLoader: imageLoader
            )
        }
    }

    private var emptyImage: some View {
        VStack(spacing: \.sixteen) {
            Spacer()
            Image(\.photoFill).font(size: \.p60).foregroundColor(\.gray)
            Text(\.imageNotAvailable).foregroundColor(\.white)
            Spacer()
        }
    }
}
