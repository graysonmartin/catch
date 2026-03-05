import SwiftUI
import CatchCore

struct LocationPickerView: View {
    @Binding var location: Location

    @Environment(MKLocationSearchService.self) private var searchService: MKLocationSearchService?
    @State private var fetcher = LocationFetcher()
    @State private var queryText = ""
    @State private var isShowingSuggestions = false
    @State private var debounceTask: Task<Void, Never>?
    @State private var isSyncingFromBinding = false
    @State private var isShowingMap = false
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space8) {
            if location.hasCoordinates, !isEditing {
                resolvedView
            } else {
                editingView
            }
        }
        .onAppear {
            if queryText.isEmpty, !location.name.isEmpty {
                isSyncingFromBinding = true
                queryText = location.name
            }
        }
        .sheet(isPresented: $isShowingMap) {
            LocationMapSheet(location: $location) { newLocation in
                isSyncingFromBinding = true
                queryText = newLocation.name
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Resolved State

    private var resolvedView: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space6) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(CatchTheme.primary)
                Text(location.name)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }

            HStack(spacing: CatchSpacing.space16) {
                Button {
                    isShowingMap = true
                } label: {
                    HStack(spacing: CatchSpacing.space4) {
                        Image(systemName: "map")
                        Text(CatchStrings.Components.viewOnMap)
                    }
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.primary)
                }

                Button {
                    startEditing()
                } label: {
                    HStack(spacing: CatchSpacing.space4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(CatchStrings.Components.changeLocation)
                    }
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.primary)
                }
            }
        }
    }

    // MARK: - Editing State

    private var editingView: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space8) {
            gpsButton
            errorDisplay
            searchField
            suggestionsList
        }
    }

    @ViewBuilder
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
            .font(.subheadline)
            .foregroundStyle(CatchTheme.primary)
        }
        .disabled(fetcher.isFetchingLocation)
    }

    @ViewBuilder
    private var errorDisplay: some View {
        if let error = fetcher.error {
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
    }

    private var searchField: some View {
        TextField(CatchStrings.Components.typeLocationName, text: $queryText)
            .onChange(of: queryText) { _, newValue in
                handleQueryChange(newValue)
            }
    }

    @ViewBuilder
    private var suggestionsList: some View {
        let suggestions = searchService?.suggestions ?? []
        if isShowingSuggestions, !suggestions.isEmpty {
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
                        .padding(.vertical, CatchSpacing.space6)
                    }
                    if result != suggestions.last {
                        Divider()
                    }
                }
            }
        }

        if searchService?.isResolving == true {
            HStack(spacing: CatchSpacing.space6) {
                ProgressView()
                    .controlSize(.small)
                Text(CatchStrings.Components.resolvingLocation)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        isEditing = true
        isSyncingFromBinding = true
        queryText = ""
        location = Location.empty
    }

    private func finishEditing() {
        isEditing = false
        isShowingSuggestions = false
    }

    private func handleQueryChange(_ newValue: String) {
        if isSyncingFromBinding {
            isSyncingFromBinding = false
            return
        }

        location.latitude = nil
        location.longitude = nil
        location.name = newValue

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
                location = resolved
            } else {
                location = Location(name: result.displayName)
            }
            searchService?.clear()
            finishEditing()
        }
    }

    private func fetchCurrentLocation() {
        Task {
            do {
                let result = try await fetcher.fetchCurrentLocation()
                location = result
                isSyncingFromBinding = true
                queryText = result.name
                isShowingSuggestions = false
                searchService?.clear()
                finishEditing()
            } catch {
                // Error already set on fetcher by fetchCurrentLocation()
            }
        }
    }
}

// MARK: - Map Sheet

private struct LocationMapSheet: View {
    @Binding var location: Location
    @Environment(\.dismiss) private var dismiss
    var onLocationChanged: ((Location) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                LocationMapPreview(location: $location) { newLocation in
                    onLocationChanged?(newLocation)
                }

                HStack(spacing: CatchSpacing.space6) {
                    Image(systemName: "hand.draw")
                        .foregroundStyle(CatchTheme.textSecondary)
                    Text(CatchStrings.Components.dragToAdjust)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                .padding(.top, CatchSpacing.space8)

                if !location.name.isEmpty {
                    Text(location.name)
                        .font(.subheadline)
                        .foregroundStyle(CatchTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, CatchSpacing.space4)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(CatchStrings.Common.done) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
