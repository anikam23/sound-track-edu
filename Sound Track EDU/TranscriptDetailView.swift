import SwiftUI

struct TranscriptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TranscriptStore

    let record: TranscriptRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(record.displayTitle)
                    .font(.headline)

                Text(record.text)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Theme.beige.ignoresSafeArea())
        .navigationTitle("Transcript")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Placeholder summarize action (no OpenAI call yet)
                Button {
                    summarizePlaceholder()
                } label: {
                    Label("Summarize", systemImage: "text.insert")
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
    }

    private func summarizePlaceholder() {
        // For now, just a lightweight toast-like feedback
        // (Replace later with real summary flow)
        #if DEBUG
        print("Summarize tapped for: \(record.displayTitle)")
        #endif
    }
}
