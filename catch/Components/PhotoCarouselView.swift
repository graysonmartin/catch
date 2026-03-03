import SwiftUI

struct PhotoCarouselView: View {
    let photos: [Data]
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 12
    var showsIndicator: Bool = true
    var accentColor: Color = CatchTheme.primary
    var emptyBackgroundColor: Color = CatchTheme.secondary.opacity(0.3)

    @State private var currentPage = 0

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

    var body: some View {
        if photos.isEmpty {
            emptyState
        } else if photos.count == 1 {
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
    }

    private var singlePhoto: some View {
        photoImage(photos[0])
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var carousel: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(photos.indices, id: \.self) { index in
                    photoImage(photos[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            if showsIndicator {
                pageIndicator
                    .padding(.bottom, Layout.indicatorBottomPadding)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: Layout.dotSpacing) {
            ForEach(photos.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(Layout.inactiveDotOpacity))
                    .frame(width: Layout.dotSize, height: Layout.dotSize)
            }
        }
        .padding(.horizontal, Layout.indicatorPaddingH)
        .padding(.vertical, Layout.indicatorPaddingV)
        .background(Capsule().fill(.black.opacity(Layout.indicatorBackgroundOpacity)))
    }

    private func photoImage(_ data: Data) -> some View {
        Group {
            if let uiImage = ImageDownsampler.shared.downsample(data: data, to: CGSize(width: height * 1.5, height: height)) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: height * Layout.emptyIconScale))
                    .foregroundStyle(accentColor.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(emptyBackgroundColor)
            }
        }
    }
}
