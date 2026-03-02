import SwiftUI
import CatchCore

struct ToastView: View {
    let toast: ToastManager.Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: CatchSpacing.space10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor)

            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 0)

            if let retry = toast.retryAction {
                Button {
                    onDismiss()
                    retry()
                } label: {
                    Text(CatchStrings.Toast.retry)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, CatchSpacing.space10)
                        .padding(.vertical, CatchSpacing.space4)
                        .background(CatchTheme.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CatchSpacing.space16)
        .padding(.vertical, CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(0.12),
            radius: 8,
            y: 4
        )
        .padding(.horizontal, CatchSpacing.space16)
    }

    // MARK: - Helpers

    private var iconName: String {
        switch toast.style {
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch toast.style {
        case .error: .red
        case .success: .green
        case .warning: CatchTheme.primary
        }
    }
}

// MARK: - Toast Overlay Modifier

struct ToastOverlayModifier: ViewModifier {
    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .padding(.top, CatchSpacing.space8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: toastManager.currentToast)
                    .zIndex(999)
                }
            }
            .animation(.spring(duration: 0.3), value: toastManager.currentToast)
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}
