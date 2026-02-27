import SwiftUI
import CatchCore

struct AddEncounterView: View {
    @Binding var selectedTab: Int
    @Binding var feedScrollToTop: Bool
    @State private var showingAddCat = false
    @State private var showingLogEncounter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: CatchSpacing.space24) {
                Spacer()

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CatchTheme.primary)

                Text(CatchStrings.Log.logCatEncounter)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)

                VStack(spacing: CatchSpacing.space16) {
                    Button {
                        showingAddCat = true
                    } label: {
                        Label(CatchStrings.Log.newCat, systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, CatchSpacing.space20)
                            .background(CatchTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
                    }

                    Button {
                        showingLogEncounter = true
                    } label: {
                        Label(CatchStrings.Log.seenAgain, systemImage: "eye.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, CatchSpacing.space20)
                            .background(CatchTheme.secondary)
                            .foregroundStyle(CatchTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
                    }
                }
                .padding(.horizontal, CatchSpacing.space32)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Tabs.log)
            .sheet(isPresented: $showingAddCat, onDismiss: switchToFeed) {
                AddCatView()
            }
            .sheet(isPresented: $showingLogEncounter, onDismiss: switchToFeed) {
                LogEncounterView()
            }
        }
    }

    private func switchToFeed() {
        selectedTab = 0
        feedScrollToTop = true
    }
}
