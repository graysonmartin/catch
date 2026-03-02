import SwiftUI
import CatchCore

struct DataExportButton: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isExporting = false
    @State private var exportFileURL: URL?
    @State private var isShowingShareSheet = false
    @State private var isShowingError = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            performExport()
        } label: {
            exportLabel
        }
        .buttonStyle(.plain)
        .disabled(isExporting)
        .sheet(isPresented: $isShowingShareSheet) {
            cleanUpExportFile()
        } content: {
            if let url = exportFileURL {
                ShareSheetView(items: [url])
            }
        }
        .alert(CatchStrings.DataExport.exportFailed, isPresented: $isShowingError) {
            Button(CatchStrings.Common.done, role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Export Label

    private var exportLabel: some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.semibold))
                .foregroundStyle(CatchTheme.primary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(CatchStrings.DataExport.exportTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)

                Text(CatchStrings.DataExport.exportSubtitle)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isExporting {
                ProgressView()
                    .tint(CatchTheme.primary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .padding(CatchSpacing.space16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    // MARK: - Export Logic

    private func performExport() {
        guard !isExporting else { return }
        isExporting = true

        Task {
            do {
                let service = SwiftDataExportService(modelContext: modelContext)
                let exportData = try await service.exportData()
                let jsonData = try service.encodeToJSON(exportData)
                let fileURL = try writeExportFile(jsonData)
                exportFileURL = fileURL
                isShowingShareSheet = true
            } catch DataExportError.noDataToExport {
                errorMessage = CatchStrings.DataExport.nothingToExport
                isShowingError = true
            } catch {
                errorMessage = CatchStrings.DataExport.exportFailedMessage
                isShowingError = true
            }
            isExporting = false
        }
    }

    private func writeExportFile(_ data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = CatchStrings.DataExport.exportFileName(Date())
        let fileURL = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }

    private func cleanUpExportFile() {
        guard let url = exportFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        exportFileURL = nil
    }
}
