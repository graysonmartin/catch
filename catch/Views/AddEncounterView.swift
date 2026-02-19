import SwiftUI

struct AddEncounterView: View {
    @Binding var selectedTab: Int
    @Binding var feedScrollToTop: Bool
    @State private var showingAddCat = false
    @State private var showingLogEncounter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(CatchTheme.primary)

                Text("Log a Cat Encounter")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)

                VStack(spacing: 16) {
                    Button {
                        showingAddCat = true
                    } label: {
                        Label("New Cat", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(CatchTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
                    }

                    Button {
                        showingLogEncounter = true
                    } label: {
                        Label("Seen Again", systemImage: "eye.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(CatchTheme.secondary)
                            .foregroundStyle(CatchTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle("Log")
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
