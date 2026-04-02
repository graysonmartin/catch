import SwiftUI
import CatchCore

struct PhotoCarouselView: View {
    let photos: [Data]
    var photoUrls: [String] = []
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 12
    var showsIndicator: Bool = true
    var isTappable: Bool = false
    var onTap: (() -> Void)?
    var accentColor: Color = CatchTheme.primary
    var emptyBackgroundColor: Color = CatchTheme.secondary.opacity(0.3)

    @State private var currentPage = 0
    @State private var isShowingFullScreen = false

    private enum Layout {
        static let dotSize: CGFloat = 6
        static let dotSpacing: CGFloat = 6
        static let indicatorPaddingH: CGFloat = 8
        static let indicatorPaddingV: CGFloat = 4
        static let indicatorBottomPadding: CGFloat = 8
        static let indicatorBackgroundOpacity: Double = 0.3
        static let inactiveDotOpacity: Double = 0.5
        static let emptyIconScale: CGFloat = 0.25
    }

    /// Total number of displayable items (local data or remote URLs).
    private var totalCount: Int {
        photos.isEmpty ? photoUrls.count : photos.count
    }

    private var hasContent: Bool {
        !photos.isEmpty || !photoUrls.isEmpty
    }

    var body: some View {
        if !hasContent {
            emptyState
        } else if totalCount == 1 {
            singlePhoto
        } else {
            carousel
        }
    }

    private var emptyState: some View {
        Image(systemName: "pawprint.fill")
            .font(.system(size: height * Layout.emptyIconScale))
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(emptyBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityLabel(CatchStrings.Accessibility.photoPlaceholder)
    }

    private func constrainedPhoto(at index: Int) -> some View {
        GeometryReader { geo in
            photoView(at: index)
                .frame(width: geo.size.width, height: height)
                .clipped()
        }
        .frame(height: height)
    }

    private var singlePhoto: some View {
        constrainedPhoto(at: 0)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .accessibilityLabel(CatchStrings.Accessibility.photoCarouselLabel(count: 1))
        .accessibilityAddTraits(isTappable || onTap != nil ? .isButton : [])
        .fullScreenCover(isPresented: $isShowingFullScreen) {
            FullScreenPhotoViewer(photos: photos, photoUrls: photoUrls, initialIndex: 0) {
                isShowingFullScreen = false
            }
        }
    }

    private var carousel: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(0..<totalCount, id: \.self) { index in
                    constrainedPhoto(at: index)
                        .tag(index)
                        .accessibilityLabel(CatchStrings.Accessibility.photoPage(index + 1, of: totalCount))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture { handleTap() }

            if showsIndicator {
                pageIndicator
                    .padding(.bottom, Layout.indicatorBottomPadding)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(CatchStrings.Accessibility.photoCarouselLabel(count: totalCount))
        .fullScreenCover(isPresented: $isShowingFullScreen) {
            FullScreenPhotoViewer(photos: photos, photoUrls: photoUrls, initialIndex: currentPage) {
                isShowingFullScreen = false
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: Layout.dotSpacing) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(Layout.inactiveDotOpacity))
                    .frame(width: Layout.dotSize, height: Layout.dotSize)
            }
        }
        .padding(.horizontal, Layout.indicatorPaddingH)
        .padding(.vertical, Layout.indicatorPaddingV)
        .background(Capsule().fill(.black.opacity(Layout.indicatorBackgroundOpacity)))
        .accessibilityHidden(true)
    }

    private func handleTap() {
        if let onTap {
            onTap()
        } else if isTappable {
            isShowingFullScreen = true
        }
    }

    @ViewBuilder
    private func photoView(at index: Int) -> some View {
        if !photos.isEmpty, index < photos.count {
            photoImage(photos[index])
        } else if !photoUrls.isEmpty, index < photoUrls.count {
            remotePhotoImage(photoUrls[index])
        } else {
            photoPlaceholder
        }
    }

    private func photoImage(_ data: Data) -> some View {
        Group {
            if let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: height * 2, height: height)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                photoPlaceholder
            }
        }
    }

    private func remotePhotoImage(_ urlString: String) -> some View {
        RemoteImageView(urlString: urlString) { photoPlaceholder }
    }

    private var photoPlaceholder: some View {
        Image(systemName: "photo")
            .font(.system(size: height * Layout.emptyIconScale))
            .foregroundStyle(accentColor.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(emptyBackgroundColor)
    }
}
