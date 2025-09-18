import SwiftUI

struct SummaryDetailView: View {
    let record: TranscriptRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(record.displayTitle)
                    .font(.title)
                    .bold()

                GroupBox("Summary") {
                    Text(record.summary?.isEmpty == false
                         ? record.summary!
                         : "No summary yet.\n\nTap **Generate Summary** to create one later.")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Original transcript") {
                    Text(record.text.isEmpty ? "—" : record.text)
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
                Button {
                    // Placeholder for future OpenAI integration.
                    // We’ll wire this up later.
                } label: {
                    Label("Generate Summary", systemImage: "sparkles")
                }
            }
        }
    }
}
