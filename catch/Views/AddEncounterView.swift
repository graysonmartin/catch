import SwiftUI
import CatchCore

struct AddEncounterView: View {
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
                        HapticService.fire(.medium)
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
                        HapticService.fire(.medium)
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
            .sheet(isPresented: $showingAddCat) {
                AddCatView()
            }
            .sheet(isPresented: $showingLogEncounter) {
                LogEncounterView()
            }
        }
    }
}
