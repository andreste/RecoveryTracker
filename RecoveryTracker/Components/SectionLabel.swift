import SwiftUI

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.rtSection)
            .kerning(0.8)
            .foregroundColor(.rtText3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RTSpacing.titlePad)
            .padding(.top, 20)
            .padding(.bottom, RTSpacing.sm)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionLabel(text: "Sleep · last 7 days")
        SectionLabel(text: "Correlations · auto-detected")
    }
    .background(Color.rtBackground)
}
