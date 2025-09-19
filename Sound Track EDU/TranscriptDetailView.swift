import SwiftUI

struct TranscriptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TranscriptStore
    @StateObject private var aiService = AISummaryService()
    @State private var showingSummary = false

    let record: TranscriptRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(record.displayTitle)
                    .font(.headline)

                Text(record.text.isEmpty ? "No transcript content available" : record.text)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Debug information
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Text length: \(record.text.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Has summary: \(record.summary?.isEmpty == false ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .background(Theme.beige.ignoresSafeArea())
        .navigationTitle("Transcript")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // AI Summary action
                if record.summary?.isEmpty == false {
                    Button {
                        showingSummary = true
                    } label: {
                        Label("View Summary", systemImage: "sparkles")
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

                // Share as a temporary text file
                Button {
                    let url = ShareHelper.temporaryFile(for: record)
                    ShareHelper.presentShareSheet(with: [url])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                // Delete this transcript
                Button(role: .destructive) {
                    store.delete(record)   // <- pass the record, not record.id
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            SummaryDetailView(record: record)
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
            for: record.text,
            subject: record.subject,
            period: record.period
        ) else {
            return
        }
        
        // Update the record with the new summary
        store.updateSummary(for: record.id, summary: summary)
        
        // Show the summary
        showingSummary = true
    }
}
