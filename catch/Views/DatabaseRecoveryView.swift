import SwiftUI

struct DatabaseRecoveryView: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onReset: () -> Void

    @State private var isShowingResetConfirmation = false
    @State private var isShowingDetails = false

    var body: some View {
        ZStack {
            CatchTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: CatchSpacing.space32) {
                    Spacer()
                        .frame(height: CatchSpacing.space48)

                    iconSection
                    textSection
                    actionsSection
                    detailsSection

                    Spacer()
                }
                .padding(.horizontal, CatchSpacing.space32)
            }
        }
        .alert(
            CatchStrings.Recovery.resetConfirmTitle,
            isPresented: $isShowingResetConfirmation
        ) {
            Button(CatchStrings.Recovery.resetConfirmAction, role: .destructive) {
                onReset()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(CatchStrings.Recovery.resetConfirmMessage)
        }
    }

    // MARK: - Sections

    private var iconSection: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 64))
            .foregroundStyle(CatchTheme.primary)
    }

    private var textSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Text(CatchStrings.Recovery.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            Text(CatchStrings.Recovery.subtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Button(action: onRetry) {
                Text(CatchStrings.Recovery.retryButton)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(CatchTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
            }

            Button {
                isShowingResetConfirmation = true
            } label: {
                Text(CatchStrings.Recovery.resetButton)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CatchTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
                    .overlay(
                        RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                            .strokeBorder(CatchTheme.textSecondary.opacity(0.2))
                    )
            }
        }
    }

    private var detailsSection: some View {
        VStack(spacing: CatchSpacing.space8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowingDetails.toggle()
                }
            } label: {
                HStack(spacing: CatchSpacing.space4) {
                    Text(CatchStrings.Recovery.technicalDetails)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary.opacity(0.6))
                    Image(systemName: isShowingDetails ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(CatchTheme.textSecondary.opacity(0.6))
                }
            }

            if isShowingDetails {
                Text(errorMessage)
                    .font(.caption2.monospaced())
                    .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(CatchSpacing.space12)
                    .frame(maxWidth: .infinity)
                    .background(CatchTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
            }
        }
        .padding(.top, CatchSpacing.space8)
    }
}
