import SwiftUI

/// Presents a `UIActivityViewController` directly from the root view controller,
/// bypassing SwiftUI's sheet system to avoid double-presentation conflicts.
enum SharePresenter {

    @MainActor
    static func present(items: [Any], onDismiss: (() -> Void)? = nil) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }

        // Walk to the topmost presented VC so we don't conflict with existing presentations
        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        presenter.present(activityVC, animated: true)
    }
}
