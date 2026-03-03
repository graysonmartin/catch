import SwiftUI

/// A full-screen overlay for viewing photos at full resolution.
/// Supports pinch-to-zoom, double-tap-to-zoom, swipe between photos,
/// and drag-to-dismiss.
struct FullScreenPhotoViewer: View {

    let photos: [Data]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentPage: Int

    private enum Layout {
        static let closeButtonSize: CGFloat = 32
        static let closeButtonPadding: CGFloat = 16
        static let counterFontSize: CGFloat = 14
        static let counterPaddingH: CGFloat = 12
        static let counterPaddingV: CGFloat = 6
        static let counterBackgroundOpacity: Double = 0.5
        static let counterCornerRadius: CGFloat = 12
    }

    init(photos: [Data], initialIndex: Int = 0, onDismiss: @escaping () -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        self._currentPage = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            photoPages

            overlay
        }
        .statusBarHidden(true)
        .transition(.opacity)
    }

    // MARK: - Photo Pages

    private var photoPages: some View {
        TabView(selection: $currentPage) {
            ForEach(photos.indices, id: \.self) { index in
                ZoomablePhotoView(
                    imageData: photos[index],
                    onDismiss: onDismiss
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }

    // MARK: - Overlay Controls

    private var overlay: some View {
        VStack {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.horizontal, Layout.closeButtonPadding)
            .padding(.top, Layout.closeButtonPadding)

            Spacer()

            if photos.count > 1 {
                pageCounter
                    .padding(.bottom, Layout.closeButtonPadding)
            }
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: Layout.closeButtonSize))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(radius: 4)
        }
        .accessibilityLabel(CatchStrings.Components.closePhotoViewer)
    }

    private var pageCounter: some View {
        Text(CatchStrings.Components.photoPageIndicator(currentPage + 1, photos.count))
            .font(.system(size: Layout.counterFontSize, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, Layout.counterPaddingH)
            .padding(.vertical, Layout.counterPaddingV)
            .background(
                Capsule()
                    .fill(.black.opacity(Layout.counterBackgroundOpacity))
            )
    }
}
