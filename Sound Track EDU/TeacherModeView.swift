import SwiftUI

struct TeacherModeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Teacher")
                .font(.largeTitle).bold()

            Text("Tools for teachers are coming soon.")
                .foregroundStyle(Theme.subtext)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.beige.ignoresSafeArea())
        .navigationTitle("Teacher")
        .navigationBarTitleDisplayMode(.large)
    }
}
