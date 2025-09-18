import SwiftUI

/// Review tab – clean list (no transcript preview). Shows date • subject • period.
struct ReviewView: View {
    @EnvironmentObject private var store: TranscriptStore
    @State private var query: String = ""

    // Filter to subject/period/title only
    private var filtered: [TranscriptRecord] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return store.records }
        return store.records.filter {
            $0.displayTitle.lowercased().contains(q) ||
            String($0.period).contains(q) ||
            $0.subject.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { rec in
                    NavigationLink(value: rec) {
                        TranscriptRow(rec: rec)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.delete(rec)                    // ← delete by record
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            let url = ShareHelper.temporaryFile(for: rec)
                            ShareHelper.presentShareSheet(with: [url])
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Review")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: TranscriptRecord.self) { rec in
                TranscriptDetailView(record: rec)
            }
            .background(Theme.beige.ignoresSafeArea())
            .tint(Theme.accent)
        }
    }
}

private struct TranscriptRow: View {
    let rec: TranscriptRecord

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(rec.displayTitle)                // e.g. "Biology • Period 1"
                .font(.title2).bold()
                .lineLimit(1)

            HStack(spacing: 12) {
                Label(rec.subject, systemImage: "book.closed")
                Label("Period \(rec.period)", systemImage: "clock")
                Spacer()
                Text(timeOnly)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
        }
        .padding(.vertical, 6)
    }

    private var timeOnly: String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: rec.createdAt)
    }
}
