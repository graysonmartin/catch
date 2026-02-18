import SwiftUI

struct PhotoCarouselView: View {
    let photos: [Data]
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 12
    var showsIndicator: Bool = true

    @State private var currentPage = 0

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
            .font(.system(size: height * 0.25))
            .foregroundStyle(CatchTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(CatchTheme.secondary.opacity(0.3))
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
                    .padding(.bottom, 8)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(photos.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(.black.opacity(0.3)))
    }

    @ViewBuilder
    private func photoImage(_ data: Data) -> some View {
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        }
    }
}
