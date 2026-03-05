import SwiftUI
import CatchCore

struct UsernameFieldView: View {
    @Binding var username: String
    @Binding var availability: UsernameAvailability
    var currentUsername: String?
    var checkAvailability: (String) async throws -> Bool

    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            HStack {
                Text("@")
                    .foregroundStyle(CatchTheme.textSecondary)
                TextField(CatchStrings.Profile.usernamePlaceholder, text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: username) { _, newValue in
                        username = newValue.lowercased()
                        scheduleAvailabilityCheck()
                    }
            }
            statusView
        }
        .onDisappear {
            checkTask?.cancel()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        let validation = UsernameValidator.validate(username)
        if username.isEmpty {
            EmptyView()
        } else if validation != .valid {
            Text(CatchStrings.Profile.validationMessage(for: validation))
                .font(.caption)
                .foregroundStyle(.red)
        } else {
            switch availability {
            case .idle:
                EmptyView()
            case .checking:
                Text(CatchStrings.Profile.usernameChecking)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            case .available:
                Text(CatchStrings.Profile.usernameAvailable)
                    .font(.caption)
                    .foregroundStyle(.green)
            case .taken:
                Text(CatchStrings.Profile.usernameTaken)
                    .font(.caption)
                    .foregroundStyle(.red)
            case .error:
                Text(CatchStrings.Profile.usernameCheckFailed)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func scheduleAvailabilityCheck() {
        checkTask?.cancel()
        let current = username
        guard UsernameValidator.validate(current) == .valid else {
            availability = .idle
            return
        }
        if let currentUsername, current == currentUsername {
            availability = .available
            return
        }
        if UsernameValidator.isReserved(current) {
            availability = .taken
            return
        }
        availability = .checking
        checkTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            do {
                let isAvailable = try await checkAvailability(current)
                guard !Task.isCancelled else { return }
                availability = isAvailable ? .available : .taken
            } catch {
                guard !Task.isCancelled else { return }
                availability = .error
            }
        }
    }
}
