import SwiftUI

struct ProfileView: View {
    let mode: ProfileMode
    @Binding var selectedTab: Int

    init(mode: ProfileMode = .own, selectedTab: Binding<Int>) {
        self.mode = mode
        self._selectedTab = selectedTab
    }

    var body: some View {
        switch mode {
        case .own:
            NavigationStack {
                OwnProfileContent(selectedTab: $selectedTab)
            }
        case .remote(let userID, let initialDisplayName):
            RemoteProfileContent(userID: userID, initialDisplayName: initialDisplayName)
        }
    }
}
