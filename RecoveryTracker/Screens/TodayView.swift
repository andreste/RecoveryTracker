import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            Text("Today")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.rtBackground)
                .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
