import SwiftUI
import CatchCore

/// Multi-step walkthrough shown to new users after profile setup.
/// Gates at the App level in `catchApp.swift`. Steps: welcome, location, suggested people.
struct NewUserWalkthroughView: View {
    @Binding var hasCompleted: Bool
    @State private var currentStep = 0

    private let totalSteps = 3

    var body: some View {
        ZStack {
            CatchTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                skipHeader

                TabView(selection: $currentStep) {
                    WalkthroughWelcomeStep()
                        .tag(0)
                    WalkthroughLocationStep()
                        .tag(1)
                    WalkthroughPeopleStep(onComplete: completeWalkthrough)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                bottomControls
            }
        }
    }

    // MARK: - Skip Header

    private var skipHeader: some View {
        HStack {
            Spacer()
            Button {
                completeWalkthrough()
            } label: {
                Text(CatchStrings.Walkthrough.skip)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .padding(.trailing, CatchSpacing.space20)
            .padding(.top, CatchSpacing.space12)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: CatchSpacing.space16) {
            pageDots

            primaryButton
        }
        .padding(.horizontal, CatchSpacing.space32)
        .padding(.bottom, CatchSpacing.space48)
    }

    private var pageDots: some View {
        HStack(spacing: CatchSpacing.space8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? CatchTheme.primary : CatchTheme.primary.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            advanceOrComplete()
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(CatchTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var buttonTitle: String {
        switch currentStep {
        case 0: return CatchStrings.Walkthrough.continueButton
        case 1: return CatchStrings.Walkthrough.next
        default: return CatchStrings.Walkthrough.done
        }
    }

    // MARK: - Actions

    private func advanceOrComplete() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            completeWalkthrough()
        }
    }

    private func completeWalkthrough() {
        hasCompleted = true
    }
}
