import SwiftUI

/// A container that adds swipe-to-delete behavior to any content view.
/// Swiping left reveals a delete button; full swipe triggers the delete action.
struct SwipeToDeleteView<Content: View>: View {
    let content: Content
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isShowingDelete = false
    @GestureState private var dragOffset: CGFloat = 0

    private let deleteWidth: CGFloat = 80
    private let fullSwipeThreshold: CGFloat = 200

    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteBackground

            content
                .offset(x: currentOffset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
    }

    // MARK: - Computed

    private var currentOffset: CGFloat {
        let total = offset + dragOffset
        // Allow swiping left (negative), clamp right swipe to 0
        return min(0, total)
    }

    // MARK: - Delete Background

    private var deleteBackground: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    isShowingDelete = false
                }
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: deleteWidth, height: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        .opacity(currentOffset < 0 ? 1 : 0)
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in
                // Only track horizontal drags that are more horizontal than vertical
                if abs(value.translation.width) > abs(value.translation.height) {
                    state = value.translation.width
                }
            }
            .onEnded { value in
                let total = offset + value.translation.width

                withAnimation(.easeOut(duration: 0.2)) {
                    if total < -fullSwipeThreshold {
                        // Full swipe — trigger delete
                        offset = 0
                        isShowingDelete = false
                        onDelete()
                    } else if total < -deleteWidth / 2 {
                        // Partial swipe — snap to show delete button
                        offset = -deleteWidth
                        isShowingDelete = true
                    } else {
                        // Swipe back — dismiss
                        offset = 0
                        isShowingDelete = false
                    }
                }
            }
    }
}
