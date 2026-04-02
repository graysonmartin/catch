import SwiftUI
import CatchCore

/// Single onboarding flow that combines the feature tour, sign-in, and
/// post-auth setup (location + find people) into one continuous experience.
struct UnifiedOnboardingView: View {
    var startPhase: Phase = .featureTour
    var onComplete: () -> Void

    @State private var phase: Phase?
    @State private var tourPage = 0
    @State private var postAuthPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Phase

    enum Phase {
        case featureTour
        case signIn
        case postAuth(Int) // 0 = location, 1 = notifications, 2 = people
    }

    private let tourPageCount = 6  // welcome through collection
    private let postAuthPageCount = 3 // location + notifications + people

    var body: some View {
        ZStack {
            CatchTheme.background
                .ignoresSafeArea()

            switch phase ?? startPhase {
            case .featureTour:
                featureTourContent
            case .signIn:
                ProfileSetupView { isNewUser in
                    if isNewUser {
                        phase = .postAuth(0)
                    } else {
                        onComplete()
                    }
                }
            case .postAuth:
                postAuthContent
            }
        }
        .onAppear {
            if phase == nil { phase = startPhase }
        }
    }

    // MARK: - Feature Tour (pages 0-5)

    private var featureTourContent: some View {
        VStack(spacing: 0) {
            TabView(selection: $tourPage) {
                welcomePage.tag(0)
                OnboardingBreedPreview().tag(1)
                OnboardingMapPreview().tag(2)
                OnboardingFeedPreview().tag(3)
                OnboardingDiaryPreview().tag(4)
                OnboardingCollectionPreview().tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: tourPage)

            tourBottomControls
        }
    }

    private var tourBottomControls: some View {
        VStack(spacing: CatchSpacing.space24) {
            pageDots(current: tourPage, total: tourPageCount)

            Button {
                if tourPage < tourPageCount - 1 {
                    tourPage += 1
                } else {
                    phase = .signIn
                }
            } label: {
                Text(tourPage == tourPageCount - 1 ? CatchStrings.Onboarding.letsGo : CatchStrings.Onboarding.next)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(CatchTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if tourPage < tourPageCount - 1 {
                Button {
                    phase = .signIn
                } label: {
                    Text(CatchStrings.Onboarding.skip)
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .frame(minHeight: CatchTheme.minTapTarget)
                }
            }
        }
        .padding(.horizontal, CatchSpacing.space32)
        .padding(.bottom, CatchSpacing.space48)
    }

    // MARK: - Post-Auth Steps

    private var postAuthContent: some View {
        VStack(spacing: 0) {
            skipHeader

            TabView(selection: $postAuthPage) {
                WalkthroughLocationStep().tag(0)
                WalkthroughNotificationStep().tag(1)
                WalkthroughPeopleStep(onComplete: onComplete).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: postAuthPage)

            postAuthBottomControls
        }
    }

    private var skipHeader: some View {
        HStack {
            Spacer()
            Button {
                onComplete()
            } label: {
                Text(CatchStrings.Walkthrough.skip)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .padding(.trailing, CatchSpacing.space20)
            .padding(.top, CatchSpacing.space12)
        }
    }

    private var postAuthBottomControls: some View {
        VStack(spacing: CatchSpacing.space16) {
            pageDots(current: postAuthPage, total: postAuthPageCount)

            Button {
                if postAuthPage < postAuthPageCount - 1 {
                    postAuthPage += 1
                } else {
                    onComplete()
                }
            } label: {
                Text(postAuthPage == postAuthPageCount - 1 ? CatchStrings.Walkthrough.done : CatchStrings.Walkthrough.next)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(CatchTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, CatchSpacing.space32)
        .padding(.bottom, CatchSpacing.space48)
    }

    // MARK: - Shared

    private func pageDots(current: Int, total: Int) -> some View {
        HStack(spacing: CatchSpacing.space8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? CatchTheme.primary : CatchTheme.primary.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CatchStrings.Accessibility.onboardingPage(current + 1, of: total))
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: CatchSpacing.space24) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(CatchTheme.primary)
                        .accessibilityHidden(true)

                    VStack(spacing: CatchSpacing.space12) {
                        Text(CatchStrings.Onboarding.appName)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(CatchTheme.textPrimary)

                        Text(CatchStrings.Onboarding.subtitle)
                            .font(.title3)
                            .foregroundStyle(CatchTheme.textSecondary)

                        Text(CatchStrings.Onboarding.detail)
                            .font(.subheadline)
                            .foregroundStyle(CatchTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(CatchSpacing.space4)
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
