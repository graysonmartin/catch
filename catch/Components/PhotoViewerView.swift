import SwiftUI

struct PhotoViewerView: View {
    let photos: [Data]
    @State var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    ZoomablePhoto(data: photos[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if abs(value.translation.height) > abs(value.translation.width) {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if abs(value.translation.height) > 100 {
                            dismiss()
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = .zero
                            }
                        }
                        isDragging = false
                    }
            )

            // Overlay UI
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                if photos.count > 1 {
                    Text("\(currentIndex + 1) of \(photos.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.black.opacity(0.4)))
                        .padding(.bottom, 24)
                }
            }
            .opacity(isDragging ? 0.3 : 1)
        }
        .statusBarHidden()
    }
}

// MARK: - Zoomable photo with pinch gesture

struct ZoomablePhoto: View {
    let data: Data
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = max(1.0, min(newScale, 5.0))
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale <= 1.0 {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                    lastScale = 1.0
                                }
                            }
                    )
                    .simultaneousGesture(
                        scale > 1.0 ?
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                        : nil
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 3.0
                                lastScale = 3.0
                            }
                        }
                    }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
