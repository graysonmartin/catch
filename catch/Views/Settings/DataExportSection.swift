import SwiftUI
import CatchCore
import UniformTypeIdentifiers

/// Settings section providing export and import functionality.
struct DataExportSection: View {
    @Environment(CatDataService.self) private var catDataService
    @Environment(ToastManager.self) private var toastManager

    @State private var isExporting = false
    @State private var exportFileURL: URL?
    @State private var isShowingShareSheet = false
    @State private var isShowingFilePicker = false
    @State private var importPreview: ImportPreview?
    @State private var isShowingImportConfirmation = false
    @State private var isImporting = false

    var body: some View {
        Section {
            exportRow
            importRow
        } header: {
            Text(CatchStrings.Export.sectionTitle)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            cleanUpExportFile()
        } content: {
            if let exportFileURL {
                ShareSheet(items: [exportFileURL])
                    .presentationDetents([.medium, .large])
            }
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.json],
            onCompletion: handleFileImport
        )
        .alert(
            CatchStrings.Export.importConfirmTitle,
            isPresented: $isShowingImportConfirmation
        ) {
            Button(CatchStrings.Export.importConfirmAction) {
                performImport()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {
                importPreview = nil
            }
        } message: {
            if let preview = importPreview {
                Text(CatchStrings.Export.importPreview(
                    cats: preview.catCount,
                    encounters: preview.encounterCount
                ))
            }
        }
    }

    // MARK: - Export Row

    private var exportRow: some View {
        Button {
            performExport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                    Text(CatchStrings.Export.exportButton)
                    Text(CatchStrings.Export.exportDescription)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                Spacer()
                if isExporting {
                    ProgressView()
                }
            }
        }
        .disabled(isExporting)
    }

    // MARK: - Import Row

    private var importRow: some View {
        Button {
            isShowingFilePicker = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                    Text(CatchStrings.Export.importButton)
                    Text(CatchStrings.Export.importDescription)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                Spacer()
                if isImporting {
                    ProgressView()
                }
            }
        }
        .disabled(isImporting)
    }

    // MARK: - Actions

    private func performExport() {
        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                let url = try ExportService.writeTemporaryFile(from: catDataService.cats)
                exportFileURL = url
                isShowingShareSheet = true
            } catch {
                toastManager.showError(CatchStrings.Export.exportFailed)
            }
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let preview = try ImportService.preview(from: url)
                importPreview = preview
                isShowingImportConfirmation = true
            } catch {
                toastManager.showError(CatchStrings.Export.importFailed)
            }
        case .failure:
            toastManager.showError(CatchStrings.Export.importFailed)
        }
    }

    private func performImport() {
        guard let preview = importPreview else { return }
        isImporting = true
        Task {
            defer {
                isImporting = false
                importPreview = nil
            }
            do {
                let cats = ImportService.convertToCats(from: preview.payload)
                try await importCats(cats)
                toastManager.showSuccess(CatchStrings.Export.importSuccess)
            } catch {
                toastManager.showError(CatchStrings.Export.importFailed)
            }
        }
    }

    /// Inserts imported cats via the data service, skipping any that already exist.
    private func importCats(_ cats: [Cat]) async throws {
        let existingIDs = Set(catDataService.cats.map(\.id))
        for cat in cats where !existingIDs.contains(cat.id) {
            _ = try await catDataService.createCat(
                name: cat.name,
                breed: cat.breed,
                location: cat.location,
                notes: cat.notes,
                isOwned: cat.isOwned,
                photos: [],
                encounterDate: cat.encounters.first?.date ?? cat.createdAt
            )
        }
        try await catDataService.loadCats()
    }

    private func cleanUpExportFile() {
        if let url = exportFileURL {
            try? FileManager.default.removeItem(at: url)
            exportFileURL = nil
        }
    }
}
