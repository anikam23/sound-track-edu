import SwiftUI

struct SaveTranscriptSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var period: String = ""
    @State private var subject: String = ""

    let onSave: (String, String, String) -> Void

    init(titleDefault: String, onSave: @escaping (String, String, String) -> Void) {
        _title = State(initialValue: titleDefault)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    TextField("Period (e.g. 3)", text: $period)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Subject (e.g. Biology)", text: $subject)
                }
            }
            .navigationTitle("Save Transcript")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, period, subject)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
