import SwiftUI
import CatchCore

/// Settings section providing data export functionality.
struct DataExportSection: View {
    @Environment(CatDataService.self) private var catDataService
    @Environment(ToastManager.self) private var toastManager

    @State private var isExporting = false
    @State private var exportFileURL: URL?
    @State private var isShowingShareSheet = false

    var body: some View {
        Section {
            exportRow
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

    private func cleanUpExportFile() {
        if let url = exportFileURL {
            try? FileManager.default.removeItem(at: url)
            exportFileURL = nil
        }
    }
}
