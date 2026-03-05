import SwiftUI
import CatchCore

struct LocationPickerView: View {
    @Binding var location: Location

    @State private var isShowingPicker = false

    var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            HStack {
                if location.hasCoordinates {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(CatchTheme.primary)
                    Text(location.name.isEmpty ? CatchStrings.Components.coordinatesSaved : location.name)
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(2)
                } else if !location.name.isEmpty {
                    Image(systemName: "mappin")
                        .foregroundStyle(CatchTheme.textSecondary)
                    Text(location.name)
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(2)
                } else {
                    Image(systemName: "mappin")
                        .foregroundStyle(CatchTheme.textSecondary)
                    Text(CatchStrings.Components.tapToSetLocation)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            LocationPickerSheet(location: $location)
        }
    }
}

// MARK: - Full Location Picker Sheet

private struct LocationPickerSheet: View {
    @Binding var location: Location
    @Environment(\.dismiss) private var dismiss
    @Environment(MKLocationSearchService.self) private var searchService: MKLocationSearchService?

    @State private var draft: Location
    @State private var fetcher = LocationFetcher()
    @State private var queryText = ""
    @State private var isShowingSuggestions = false
    @State private var debounceTask: Task<Void, Never>?
    @State private var isSyncingFromBinding = false

    init(location: Binding<Location>) {
        _location = location
        _draft = State(initialValue: location.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchSection
                mapSection
                bottomBar
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Common.location)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CatchStrings.Components.confirmLocation) {
                        location = draft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!draft.hasCoordinates)
                }
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(CatchStrings.Components.typeLocationName, text: $queryText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, CatchSpacing.space8)
                .onChange(of: queryText) { _, newValue in
                    handleQueryChange(newValue)
                }

            if isShowingSuggestions {
                suggestionsList
            }

            if searchService?.isResolving == true {
                HStack(spacing: CatchSpacing.space6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(CatchStrings.Components.resolvingLocation)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                .padding(.horizontal)
                .padding(.bottom, CatchSpacing.space8)
            }
        }
    }

    @ViewBuilder
    private var suggestionsList: some View {
        let suggestions = searchService?.suggestions ?? []
        if !suggestions.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { result in
                        Button {
                            selectSuggestion(result)
                        } label: {
                            HStack(spacing: CatchSpacing.space8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(CatchTheme.primary)
                                    .font(.body)
                                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                                    Text(result.title)
                                        .font(.subheadline)
                                        .foregroundStyle(CatchTheme.textPrimary)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(CatchTheme.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, CatchSpacing.space8)
                            .padding(.horizontal)
                        }
                        if result != suggestions.last {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        ZStack {
            if draft.hasCoordinates {
                LocationMapPreview(location: $draft) { newLocation in
                    isSyncingFromBinding = true
                    queryText = newLocation.name
                }
            } else {
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadius)
                    .fill(Color(.systemFill))
                    .overlay {
                        VStack(spacing: CatchSpacing.space8) {
                            Image(systemName: "map")
                                .font(.largeTitle)
                                .foregroundStyle(CatchTheme.textSecondary)
                            Text(CatchStrings.Components.tapToSetLocation)
                                .font(.subheadline)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .padding(.vertical, CatchSpacing.space4)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: CatchSpacing.space8) {
            if draft.hasCoordinates, !draft.name.isEmpty {
                HStack(spacing: CatchSpacing.space6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(CatchTheme.primary)
                    Text(draft.name)
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            if draft.hasCoordinates {
                HStack(spacing: CatchSpacing.space6) {
                    Image(systemName: "hand.draw")
                        .foregroundStyle(CatchTheme.textSecondary)
                    Text(CatchStrings.Components.dragToAdjust)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }

            gpsButton
                .padding(.horizontal)

            if let error = fetcher.error {
                errorDisplay(error)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, CatchSpacing.space8)
    }

    private var gpsButton: some View {
        Button {
            fetchCurrentLocation()
        } label: {
            HStack(spacing: CatchSpacing.space6) {
                if fetcher.isFetchingLocation {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CatchTheme.primary)
                } else {
                    Image(systemName: "location.fill")
                }
                Text(fetcher.isFetchingLocation
                     ? CatchStrings.Components.gettingLocation
                     : CatchStrings.Components.useCurrentLocation)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(CatchTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, CatchSpacing.space10)
            .background(
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall)
                    .fill(CatchTheme.primary.opacity(0.12))
            )
        }
        .disabled(fetcher.isFetchingLocation)
    }

    @ViewBuilder
    private func errorDisplay(_ error: String) -> some View {
        HStack(spacing: CatchSpacing.space4) {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
            if error.contains("Settings") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(CatchStrings.Components.openSettings)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CatchTheme.primary)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleQueryChange(_ newValue: String) {
        if isSyncingFromBinding {
            isSyncingFromBinding = false
            return
        }

        debounceTask?.cancel()

        guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchService?.clear()
            isShowingSuggestions = false
            return
        }

        isShowingSuggestions = true
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            searchService?.updateQuery(newValue)
        }
    }

    private func selectSuggestion(_ result: LocationSearchResult) {
        debounceTask?.cancel()
        isShowingSuggestions = false
        isSyncingFromBinding = true
        queryText = result.displayName

        Task {
            if let resolved = await searchService?.resolve(result) {
                draft = resolved
            } else {
                draft = Location(name: result.displayName)
            }
            searchService?.clear()
        }
    }

    private func fetchCurrentLocation() {
        Task {
            do {
                let result = try await fetcher.fetchCurrentLocation()
                draft = result
                isSyncingFromBinding = true
                queryText = result.name
                isShowingSuggestions = false
                searchService?.clear()
            } catch {
                // Error already set on fetcher
            }
        }
    }
}
