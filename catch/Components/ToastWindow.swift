import SwiftUI
import CatchCore

/// A passthrough UIWindow that displays toasts above all presented views,
/// including sheets and fullScreenCovers.
///
/// Normal overlays are hidden behind modals because they're attached to the
/// parent view hierarchy. This window sits at a higher window level so toasts
/// always remain visible.
@MainActor
final class ToastWindow {

    private var overlayWindow: UIWindow?
    private var hostingController: UIHostingController<AnyView>?

    func install(in windowScene: UIWindowScene, toastManager: ToastManager) {
        let rootView = ToastWindowContent(toastManager: toastManager)
        let hosting = UIHostingController(rootView: AnyView(rootView))
        hosting.view.backgroundColor = .clear
        hosting.view.isUserInteractionEnabled = true

        let window = PassthroughWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.rootViewController = hosting
        window.isHidden = false

        overlayWindow = window
        hostingController = hosting
    }
}

// MARK: - Passthrough Window

/// A UIWindow subclass that passes through touches to the views below,
/// except when the touch hits a non-clear area (i.e. the toast itself).
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }

        // If the hit landed on the root hosting controller's background view,
        // pass the touch through. Only intercept touches on actual toast content.
        if hitView == rootViewController?.view {
            return nil
        }
        return hitView
    }
}

// MARK: - Toast Window Content

private struct ToastWindowContent: View {
    let toastManager: ToastManager

    var body: some View {
        VStack {
            if let toast = toastManager.currentToast {
                ToastView(toast: toast) {
                    toastManager.dismiss()
                }
                .padding(.top, CatchSpacing.space8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .animation(.spring(duration: 0.3), value: toastManager.currentToast)
    }
}
