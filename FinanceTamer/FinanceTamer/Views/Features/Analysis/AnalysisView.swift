import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Some")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Назад")
                        }
                        .tint(Color.navigation)
                    }
                }
            }
    }
}

#Preview {
    AnalysisView()
}
