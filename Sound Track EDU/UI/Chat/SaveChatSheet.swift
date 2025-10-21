import SwiftUI

struct SaveChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var discussionTopic: String = ""
    @State private var subject: String = ""
    @State private var teacher: String = ""
    @State private var period: String = ""
    @State private var term: String = "Semester"
    @State private var termNumber: String = "1"
    
    let onSave: (String, String, String, String, String, String) -> Void
    
    init(onSave: @escaping (String, String, String, String, String, String) -> Void) {
        self.onSave = onSave
    }
    
    private var maxTermNumber: Int {
        switch term {
        case "Semester":
            return 2
        case "Trimester":
            return 3
        case "Quarter":
            return 4
        default:
            return 4
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Discussion Topic", text: $discussionTopic)
                    TextField("Subject (e.g. Biology)", text: $subject)
                    TextField("Teacher", text: $teacher)
                    TextField("Period (e.g. 3)", text: $period)
                        .keyboardType(.numbersAndPunctuation)
                }
                
                Section(header: Text("Term")) {
                    Picker("Term Type", selection: $term) {
                        Text("Semester").tag("Semester")
                        Text("Trimester").tag("Trimester")
                        Text("Quarter").tag("Quarter")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: term) { _, newTerm in
                        // Reset term number if it's now invalid for the new term type
                        let currentNumber = Int(termNumber) ?? 1
                        let maxForNewTerm = newTerm == "Semester" ? 2 : newTerm == "Trimester" ? 3 : 4
                        if currentNumber > maxForNewTerm {
                            termNumber = "1"
                        }
                    }
                    
                    Picker("Term Number", selection: $termNumber) {
                        ForEach(1...maxTermNumber, id: \.self) { number in
                            Text("\(number)").tag("\(number)")
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Save Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(discussionTopic, subject, teacher, period, term, termNumber)
                        dismiss()
                    }
                    .disabled(discussionTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .dismissKeyboardOnTap()
        }
    }
}

#Preview {
    SaveChatSheet { topic, subject, teacher, period, term, termNumber in
        print("Saving: \(topic)")
    }
}
