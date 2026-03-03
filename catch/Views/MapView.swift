import SwiftUI
import SwiftData
import CatchCore

// MARK: - SwiftUI wrapper

struct CatMapView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @Environment(CKSocialFeedService.self) private var socialFeedService: CKSocialFeedService?
    @Binding var selectedTab: Int
    @State private var selectedCat: Cat?
    @State private var selectedRemote: RemotePinSelection?
    @State private var clusterSelection: ClusterSelection?
    @State private var showMissingLocationSheet = false

    private var catsWithLocation: [Cat] {
        cats.filter { $0.location.hasCoordinates }
    }

    private var catsWithoutLocation: [Cat] {
        cats.filter { !$0.location.hasCoordinates }
    }

    /// One pin per unique remote cat — the latest encounter location per cat record.
    private var remotePins: [MapPin] {
        var latestByRecord: [String: (CloudEncounter, CloudCat?, CloudUserProfile)] = [:]
        for item in socialFeedService?.remoteEncounters ?? [] {
            guard case .remote(let encounter, let cat, let owner, _) = item else { continue }
            guard encounter.locationLatitude != nil, encounter.locationLongitude != nil else { continue }
            if let existing = latestByRecord[encounter.catRecordName] {
                if encounter.date > existing.0.date {
                    latestByRecord[encounter.catRecordName] = (encounter, cat, owner)
                }
            } else {
                latestByRecord[encounter.catRecordName] = (encounter, cat, owner)
            }
        }
        return latestByRecord.values.map { .remote(encounter: $0, cat: $1, owner: $2) }
    }

    private var allPins: [MapPin] {
        catsWithLocation.map { .local($0) } + remotePins
    }

    private func allEncounters(forCatRecord recordName: String) -> [CloudEncounter] {
        (socialFeedService?.remoteEncounters ?? []).compactMap { item in
            guard case .remote(let encounter, _, _, _) = item,
                  encounter.catRecordName == recordName else { return nil }
            return encounter
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allPins.isEmpty {
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
                            pins: allPins,
                            onSelectPin: { pin in
                                switch pin {
                                case .local(let cat):
                                    selectedCat = cat
                                case .remote(let encounter, let cat, let owner):
                                    selectedRemote = RemotePinSelection(
                                        cat: cat,
                                        encounters: allEncounters(forCatRecord: encounter.catRecordName),
                                        owner: owner
                                    )
                                }
                            },
                            onSelectCluster: { pins in
                                clusterSelection = ClusterSelection(pins: pins)
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
            .navigationDestination(item: $selectedCat) { cat in
                CatProfileView(cat: cat)
            }
            .navigationDestination(item: $selectedRemote) { selection in
                if let cat = selection.cat {
                    RemoteCatProfileView(
                        cat: cat,
                        encounters: selection.encounters,
                        ownerName: selection.owner.displayName
                    )
                }
            }
            .sheet(item: $clusterSelection) { selection in
                ClusterListSheet(pins: selection.pins) { pin in
                    clusterSelection = nil
                    switch pin {
                    case .local(let cat):
                        selectedCat = cat
                    case .remote(let encounter, let cat, let owner):
                        selectedRemote = RemotePinSelection(
                            cat: cat,
                            encounters: allEncounters(forCatRecord: encounter.catRecordName),
                            owner: owner
                        )
                    }
                }
            }
            .sheet(isPresented: $showMissingLocationSheet) {
                MissingLocationSheet(cats: catsWithoutLocation) { cat in
                    showMissingLocationSheet = false
                    selectedCat = cat
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
                           let uiImage = ImageDownsampler.shared.downsample(data: photoData, to: CGSize(width: 44, height: 44)) {
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
                            Text(cat.displayName)
                                .font(.headline)
                                .foregroundStyle(cat.isUnnamed ? CatchTheme.textSecondary : CatchTheme.textPrimary)
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
    let pins: [MapPin]
}

// MARK: - Cluster list sheet

struct ClusterListSheet: View {
    let pins: [MapPin]
    let onSelect: (MapPin) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(pins.indices, id: \.self) { index in
                let pin = pins[index]
                Button {
                    onSelect(pin)
                } label: {
                    HStack(spacing: CatchSpacing.space12) {
                        pinPhoto(pin)

                        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                            Text(pin.displayName)
                                .font(.headline)
                                .foregroundStyle(CatchTheme.textPrimary)
                            pinSubtitle(pin)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(CatchStrings.Map.catsHere(pins.count))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func pinPhoto(_ pin: MapPin) -> some View {
        if let photoData = pin.photoData,
           let uiImage = ImageDownsampler.shared.downsample(data: photoData, to: CGSize(width: 44, height: 44)) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(
                    pin.isRemote ? CatchTheme.remotePinColor : CatchTheme.primary,
                    lineWidth: 1.5
                ))
        } else {
            Image(systemName: "cat.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(pin.isRemote ? CatchTheme.remotePinColor : CatchTheme.primary)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private func pinSubtitle(_ pin: MapPin) -> some View {
        switch pin {
        case .local(let cat):
            if !cat.location.name.isEmpty {
                Text(cat.location.name)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        case .remote(let encounter, _, let owner):
            Text(CatchStrings.Map.spottedBy(owner.displayName))
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
            if !encounter.locationName.isEmpty {
                Text(encounter.locationName)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }
}
