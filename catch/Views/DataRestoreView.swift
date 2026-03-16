import SwiftUI
import SwiftData
import CatchCore

/// Shown after login when the local database is empty but the server may have data.
/// Automatically restores cats and encounters, then transitions to the main app.
struct DataRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(DefaultRestoreService.self) private var restoreService
    @Environment(ToastManager.self) private var toastManager

    var onComplete: () -> Void

    @State private var isActuallyRestoring = false
    @State private var hasFinished = false

    var body: some View {
        ZStack {
            CatchTheme.background.ignoresSafeArea()
            if isActuallyRestoring {
                PawLoadingView(label: CatchStrings.Restore.restoringData)
            }
        }
        .task {
            await performRestore()
        }
    }

    // MARK: - Private

    private func performRestore() async {
        guard !hasFinished else { return }

        guard let ownerID = authService.authState.user?.id else {
            onComplete()
            return
        }

        let localCatCount = (try? modelContext.fetchCount(FetchDescriptor<Cat>())) ?? 0
        guard localCatCount == 0 else {
            onComplete()
            return
        }

        isActuallyRestoring = true

        do {
            _ = try await restoreService.insertRestoredData(
                ownerID: ownerID,
                into: modelContext
            )
        } catch {
            toastManager.showError(CatchStrings.Restore.restoreFailed)
        }

        hasFinished = true
        onComplete()
    }
}
