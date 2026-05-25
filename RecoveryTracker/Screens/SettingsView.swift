import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.rtBackground)
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
