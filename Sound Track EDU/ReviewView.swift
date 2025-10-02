import SwiftUI

/// Review tab – organized by Period/Subject with clean grouping
struct ReviewView: View {
    @EnvironmentObject private var store: TranscriptStore
    @EnvironmentObject private var alertSync: AlertSyncService
    @StateObject private var hudManager = AlertHUDManager()
    @State private var query: String = ""
    @State private var showingSummary: TranscriptRecord?

    // Group records by subject + period, then by date
    private var groupedRecords: [(String, [(String, [TranscriptRecord])])] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = q.isEmpty ? store.records : store.records.filter {
            $0.displayTitle.lowercased().contains(q)
            || String($0.period).contains(q)
            || $0.subject.lowercased().contains(q)
        }

        let subjectPeriodGroups = Dictionary(grouping: filtered) { r in
            let teacherText = r.teacher.isEmpty ? "" : " • \(r.teacher)"
            return "\(r.subject) • \(r.termDisplay) • Period \(r.period)\(teacherText)"
        }

        return subjectPeriodGroups
            .map { (subjectPeriod, records) in
                let df = DateFormatter()
                df.dateFormat = "MMM d, yyyy"
                let dateGroups = Dictionary(grouping: records) { df.string(from: $0.createdAt) }
                let sortedDateGroups = dateGroups.sorted { $0.key > $1.key }
                return (subjectPeriod, sortedDateGroups)
            }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedRecords, id: \.0) { subjectPeriod, dateGroups in
                    Section {
                        ForEach(dateGroups, id: \.0) { dateString, records in
                            // Date chip (neutral, warm)
                            Text(dateString)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Theme.card) // uses your lighter airy option
                                )
                                .listRowBackground(Theme.beige)

                            // Card rows
                            ForEach(records.sorted { $0.createdAt > $1.createdAt }) { record in
                                NavigationLink(value: record) {
                                    TranscriptRowCard(record: record) {
                                        showingSummary = record
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Theme.beige)
                            }
                        }
                    } header: {
                        Text(subjectPeriod)
                            .textCase(nil)
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.beige.ignoresSafeArea())
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: TranscriptRecord.self) { record in
                TranscriptDetailView(record: record)
            }
        }
        .tint(Theme.accent)
        .alertBannerOverlay(hudManager)
        .onChange(of: alertSync.lastReceivedAlert) { _, newAlert in
            if let alert = newAlert {
                hudManager.showAlert(alert)
            }
        }
        .sheet(item: $showingSummary) { record in
            SummaryDetailView(record: record)
        }
    }
}

// MARK: - Transcript Row (time on top, transcript below)
// Uses Theme.card (your lighter airy value), plus very subtle border + shadow.
private struct TranscriptRowCard: View {
    let record: TranscriptRecord
    let onSummaryTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Left stack: time on its own line, transcript below (full width)
            VStack(alignment: .leading, spacing: 8) {
                Text(timeString)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !record.text.isEmpty {
                    Text(record.text)
                        .font(.body)
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(3)
                } else {
                    Text(record.title.isEmpty ? "Untitled" : record.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Summary indicator
            if record.summary?.isEmpty == false {
                Button(action: onSummaryTap) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                        .font(.title3)
                        .padding(6)
                        .background(Theme.accent.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View AI summary")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1) // subtle pop
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.accent.opacity(0.05), lineWidth: 0.25) // hairline border
        )
        .padding(.vertical, 4)
    }

    private var timeString: String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: record.createdAt)
    }
}
