import SwiftUI

struct TrainingView: View {
    var body: some View {
        NavigationStack {
            Text("Training")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.rtBackground)
                .navigationTitle("Training")
        }
    }
}

#Preview {
    TrainingView()
}
