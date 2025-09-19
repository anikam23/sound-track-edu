import SwiftUI

struct SummaryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TranscriptStore
    @StateObject private var aiService = AISummaryService()
    
    let record: TranscriptRecord
    
    // Get the current record from the store to ensure we have the latest data
    private var currentRecord: TranscriptRecord {
        store.records.first { $0.id == record.id } ?? record
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(currentRecord.displayTitle)
                    .font(.title)
                    .bold()

                GroupBox("Summary") {
                    Text(currentRecord.summary?.isEmpty == false
                         ? currentRecord.summary!
                         : "No summary yet.\n\nTap **Generate Summary** to create one later.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Original transcript") {
                    Text(currentRecord.text.isEmpty ? "—" : currentRecord.text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if currentRecord.summary?.isEmpty == false {
                    Button("Done") {
                        dismiss()
                    }
                } else {
                    Button {
                        Task {
                            await generateSummary()
                        }
                    } label: {
                        if aiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Label("Generate Summary", systemImage: "sparkles")
                        }
                    }
                    .disabled(aiService.isLoading)
                }
            }
        }
        .alert("Summary Error", isPresented: .constant(aiService.errorMessage != nil)) {
            Button("OK") {
                aiService.errorMessage = nil
            }
        } message: {
            Text(aiService.errorMessage ?? "")
        }
    }
    
    private func generateSummary() async {
        guard let summary = await aiService.generateSummary(
            for: currentRecord.text,
            subject: currentRecord.subject,
            period: currentRecord.period
        ) else {
            print("Failed to generate summary")
            return
        }
        
        print("Generated summary: \(summary)")
        
        // Update the record with the new summary
        store.updateSummary(for: currentRecord.id, summary: summary)
        
        print("Updated store with summary for record: \(currentRecord.id)")
    }
}
