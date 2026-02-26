import SwiftUI
import SwiftData

// MARK: - SwiftUI wrapper

struct CatMapView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @Binding var selectedTab: Int
    @State private var selectedCat: Cat?
    @State private var showProfile = false
    @State private var clusterSelection: ClusterSelection?
    @State private var showMissingLocationSheet = false

    private var catsWithLocation: [Cat] {
        cats.filter { $0.location.hasCoordinates }
    }

    private var catsWithoutLocation: [Cat] {
        cats.filter { !$0.location.hasCoordinates }
    }

    var body: some View {
        NavigationStack {
            Group {
                if catsWithLocation.isEmpty {
                    EmptyStateView(
                        icon: "map",
                        title: CatchStrings.Map.emptyTitle,
                        subtitle: CatchStrings.Map.emptySubtitle,
                        actionLabel: CatchStrings.Map.emptyAction,
                        action: { selectedTab = 1 }
                    )
                } else {
                    ZStack(alignment: .top) {
                        ClusterMapView(
                            cats: catsWithLocation,
                            onSelectCat: { cat in
                                selectedCat = cat
                                showProfile = true
                            },
                            onSelectCluster: { cats in
                                clusterSelection = ClusterSelection(cats: cats)
                            }
                        )

                        if !catsWithoutLocation.isEmpty {
                            Button {
                                showMissingLocationSheet = true
                            } label: {
                                HStack(spacing: CatchSpacing.space6) {
                                    Image(systemName: "eye.slash")
                                        .font(.caption2)
                                    Text(CatchStrings.Map.catsNotShown(catsWithoutLocation.count))
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, CatchSpacing.space12)
                                .padding(.vertical, CatchSpacing.space8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, CatchSpacing.space8)
                        }
                    }
                }
            }
            .navigationTitle(CatchStrings.Tabs.map)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showProfile) {
                if let cat = selectedCat {
                    CatProfileView(cat: cat)
                }
            }
            .sheet(item: $clusterSelection) { selection in
                ClusterListSheet(cats: selection.cats) { cat in
                    clusterSelection = nil
                    selectedCat = cat
                    showProfile = true
                }
            }
            .sheet(isPresented: $showMissingLocationSheet) {
                MissingLocationSheet(cats: catsWithoutLocation) { cat in
                    showMissingLocationSheet = false
                    selectedCat = cat
                    showProfile = true
                }
            }
        }
    }
}

// MARK: - Missing location sheet

struct MissingLocationSheet: View {
    let cats: [Cat]
    let onSelect: (Cat) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(cats) { cat in
                Button {
                    onSelect(cat)
                } label: {
                    HStack(spacing: CatchSpacing.space12) {
                        if let photoData = cat.photos.first,
                           let uiImage = ImageDownsampler.downsample(data: photoData, to: CGSize(width: 44, height: 44)) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "cat.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(CatchTheme.primary)
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                            Text(cat.name)
                                .font(.headline)
                                .foregroundStyle(CatchTheme.textPrimary)
                            Text(CatchStrings.Map.noLocationSet)
                                .font(.caption)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }

                        Spacer()

                        Text(CatchStrings.Common.edit.lowercased())
                            .font(.caption.weight(.medium))
                            .foregroundStyle(CatchTheme.primary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(CatchStrings.Map.missingLocationsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ClusterSelection: Identifiable {
    let id = UUID()
    let cats: [Cat]
}

// MARK: - Cluster list sheet

struct ClusterListSheet: View {
    let cats: [Cat]
    let onSelect: (Cat) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(cats) { cat in
                Button {
                    onSelect(cat)
                } label: {
                    HStack(spacing: CatchSpacing.space12) {
                        if let photoData = cat.photos.first,
                           let uiImage = ImageDownsampler.downsample(data: photoData, to: CGSize(width: 44, height: 44)) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "cat.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(CatchTheme.primary)
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                            Text(cat.name)
                                .font(.headline)
                                .foregroundStyle(CatchTheme.textPrimary)
                            if !cat.location.name.isEmpty {
                                Text(cat.location.name)
                                    .font(.caption)
                                    .foregroundStyle(CatchTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(CatchStrings.Map.catsHere(cats.count))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
