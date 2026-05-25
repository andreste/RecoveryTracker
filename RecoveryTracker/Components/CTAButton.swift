import SwiftUI

struct CTAButton: View {
    let title: String
    var systemIcon: String? = nil
    var color: Color = .rtTeal
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: RTSpacing.sm) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.rtHeadline)
                    .kerning(-0.2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(color)
            .cornerRadius(RTRadius.button)
            .rtCTAShadow(color: color)
        }
    }
}

struct SecondaryCTAButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rtSubhead)
                .kerning(-0.2)
                .foregroundColor(.rtText3)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CTAButton(title: "Connect Apple Health", systemIcon: "applelogo")
        CTAButton(title: "Continue", color: .rtTeal)
        SecondaryCTAButton(title: "Maybe later")
    }
    .padding()
    .background(Color.rtBackground)
}
