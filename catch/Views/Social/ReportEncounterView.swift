import SwiftUI
import CatchCore

struct ReportEncounterView: View {
    let encounterRecordName: String

    @Environment(SupabaseReportService.self) private var reportService
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ReportCategory?
    @State private var reason = ""
    @State private var isSubmitting = false

    private var canSubmit: Bool {
        selectedCategory != nil && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CatchSpacing.space24) {
                    categorySection
                    reasonSection
                    submitButton
                }
                .padding()
            }
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Report.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(CatchStrings.Common.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space12) {
            Text(CatchStrings.Report.categoryPrompt)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CatchTheme.textPrimary)

            ForEach(ReportCategory.allCases, id: \.self) { category in
                categoryRow(category)
            }
        }
    }

    private func categoryRow(_ category: ReportCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            HStack {
                Text(displayName(for: category))
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)

                Spacer()

                Image(systemName: selectedCategory == category ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedCategory == category ? CatchTheme.primary : CatchTheme.textSecondary)
            }
            .padding()
            .background(CatchTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reason

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space8) {
            TextField(CatchStrings.Report.reasonPlaceholder, text: $reason, axis: .vertical)
                .lineLimit(3...6)
                .font(.subheadline)
                .padding()
                .background(CatchTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
                .onChange(of: reason) { _, newValue in
                    reason = TextInputLimits.enforceLimit(text: newValue, limit: TextInputLimits.reportReason)
                }

            if TextInputLimits.shouldShowCount(text: reason, limit: TextInputLimits.reportReason) {
                Text("\(TextInputLimits.remaining(text: reason, limit: TextInputLimits.reportReason))")
                    .font(.caption)
                    .foregroundStyle(
                        TextInputLimits.isAtLimit(text: reason, limit: TextInputLimits.reportReason)
                            ? .red
                            : CatchTheme.textSecondary
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(isSubmitting ? CatchStrings.Report.submitting : CatchStrings.Report.submit)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? CatchTheme.primary : CatchTheme.textSecondary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        }
        .disabled(!canSubmit)
    }

    // MARK: - Actions

    private func submit() async {
        guard let category = selectedCategory else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await reportService.submitReport(
                encounterRecordName: encounterRecordName,
                category: category,
                reason: reason
            )
            toastManager.showSuccess(CatchStrings.Toast.reportSuccess)
            dismiss()
        } catch let error as ReportError where error == .alreadyReported {
            toastManager.showError(CatchStrings.Report.alreadyReported)
            dismiss()
        } catch {
            toastManager.showError(CatchStrings.Toast.reportFailed)
        }
    }

    // MARK: - Helpers

    private func displayName(for category: ReportCategory) -> String {
        switch category {
        case .spam: CatchStrings.Report.categorySpam
        case .inappropriate: CatchStrings.Report.categoryInappropriate
        case .harassment: CatchStrings.Report.categoryHarassment
        case .other: CatchStrings.Report.categoryOther
        }
    }
}
