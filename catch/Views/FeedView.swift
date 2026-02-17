import SwiftUI
import SwiftData

struct FeedView: View {
    @Query(sort: \Encounter.date, order: .reverse) private var encounters: [Encounter]
    @Query private var cats: [Cat]
    @Binding var scrollToTop: Bool

    var body: some View {
        let _ = cats // Observe cat changes so feed items refresh after edits
        NavigationStack {
            Group {
                if encounters.isEmpty {
                    EmptyStateView(
                        icon: "pawprint.circle",
                        title: "No Encounters Yet",
                        subtitle: "Log your first cat encounter using the Log tab."
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(encounters) { encounter in
                                    if let cat = encounter.cat {
                                        NavigationLink(value: cat) {
                                            FeedItemView(encounter: encounter)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        FeedItemView(encounter: encounter)
                                    }
                                }
                            }
                            .padding()
                            .id("feedTop")
                        }
                        .onChange(of: scrollToTop) {
                            if scrollToTop {
                                withAnimation {
                                    proxy.scrollTo("feedTop", anchor: .top)
                                }
                                scrollToTop = false
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle("Feed")
            .navigationDestination(for: Cat.self) { cat in
                CatProfileView(cat: cat)
            }
        }
    }
}
