import SwiftUI

@MainActor
@Observable
final class ToastManager {

    // MARK: - Types

    enum ToastStyle {
        case error
        case success
        case warning
    }

    struct Toast: Identifiable, Equatable {
        let id: UUID
        let message: String
        let style: ToastStyle
        var retryAction: (() -> Void)?

        static func == (lhs: Toast, rhs: Toast) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - State

    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    private static let autoDismissDelay: Duration = .seconds(3)

    // MARK: - Public API

    func showError(_ message: String, retryAction: (() -> Void)? = nil) {
        show(message: message, style: .error, retryAction: retryAction)
    }

    func showSuccess(_ message: String) {
        show(message: message, style: .success)
    }

    func showWarning(_ message: String) {
        show(message: message, style: .warning)
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        currentToast = nil
    }

    // MARK: - Private

    private func show(message: String, style: ToastStyle, retryAction: (() -> Void)? = nil) {
        dismissTask?.cancel()

        let toast = Toast(
            id: UUID(),
            message: message,
            style: style,
            retryAction: retryAction
        )
        currentToast = toast

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: Self.autoDismissDelay)
            guard !Task.isCancelled else { return }
            self?.currentToast = nil
        }
    }
}
