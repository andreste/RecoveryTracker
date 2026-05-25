import SwiftUI

struct TrendsView: View {
    var body: some View {
        NavigationStack {
            Text("Trends")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.rtBackground)
                .navigationTitle("Trends")
        }
    }
}

#Preview {
    TrendsView()
}
