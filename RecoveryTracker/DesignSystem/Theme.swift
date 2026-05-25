import SwiftUI
import UIKit

// MARK: - Color tokens

extension Color {
    // Semantic surface colors — adapt automatically to light/dark mode
    static let rtBackground  = Color(UIColor.systemGroupedBackground)   // #F2F2F7 / #000000
    static let rtCard        = Color(UIColor.systemBackground)           // #FFFFFF / #1C1C1E
    static let rtCard2       = Color(UIColor.secondarySystemBackground)  // for nested cards

    // Text hierarchy — adaptive
    static let rtText        = Color(UIColor.label)
    static let rtText2       = Color(UIColor.secondaryLabel)             // ~78% opacity
    static let rtText3       = Color(UIColor.tertiaryLabel)              // ~60% opacity
    static let rtText4       = Color(UIColor.quaternaryLabel)            // ~30% opacity
    static let rtSeparator   = Color(UIColor.separator)

    // Brand — fixed, never inverted
    static let rtTeal   = Color(red: 15/255,  green: 181/255, blue: 166/255)  // #0FB5A6 · Good/Positive
    static let rtAmber  = Color(red: 245/255, green: 165/255, blue: 36/255)   // #F5A524 · Caution/Moderate
    static let rtCoral  = Color(red: 242/255, green: 84/255,  blue: 91/255)   // #F2545B · Poor/High cost
    static let rtBlue   = Color(red: 10/255,  green: 132/255, blue: 255/255)  // #0A84FF · System/Links
    static let rtPurple = Color(red: 124/255, green: 92/255,  blue: 255/255)  // #7C5CFF · Sleep/REM

    // Soft tinted fills (used as icon tile backgrounds, card tints)
    static let rtTealSoft   = Color.rtTeal.opacity(0.12)
    static let rtAmberSoft  = Color.rtAmber.opacity(0.14)
    static let rtCoralSoft  = Color.rtCoral.opacity(0.13)
    static let rtPurpleSoft = Color.rtPurple.opacity(0.12)
}

// MARK: - Typography tokens
// SF Pro is the system font on iOS — no import needed.
// Apply .monospacedDigit() on metric Text views (HRV, HR, scores, durations).

extension Font {
    static let rtHeroScore   = Font.system(size: 60, weight: .bold)          // Readiness score numeral
    static let rtLargeTitle  = Font.system(size: 34, weight: .bold)          // Screen title
    static let rtHeroNumeric = Font.system(size: 32, weight: .bold)          // Sleep / load hero values
    static let rtTitle2      = Font.system(size: 22, weight: .bold)          // Chart summary values
    static let rtHeadline    = Font.system(size: 17, weight: .semibold)      // CTA buttons, primary labels
    static let rtBody        = Font.system(size: 16, weight: .semibold)      // List row labels
    static let rtSubhead     = Font.system(size: 15, weight: .medium)        // Subtitle, secondary body
    static let rtFootnote    = Font.system(size: 13, weight: .medium)        // Score baseline, notes
    static let rtCaption     = Font.system(size: 12, weight: .semibold)      // Metric labels, row metadata
    static let rtSection     = Font.system(size: 11, weight: .bold)          // Section headers (uppercase)
    static let rtTabLabel    = Font.system(size: 10, weight: .semibold)      // Tab bar labels, chart axes
}

// MARK: - Spacing tokens (multiples of 4)

enum RTSpacing {
    static let xs: CGFloat     = 4
    static let sm: CGFloat     = 8
    static let gap: CGFloat    = 10
    static let md: CGFloat     = 12
    static let rowPad: CGFloat = 14   // internal row padding
    static let cardPad: CGFloat = 16  // card internal padding / screen gutter
    static let titlePad: CGFloat = 20 // large title & section label horizontal padding
    static let lg: CGFloat     = 24
    static let xl: CGFloat     = 32
}

// MARK: - Corner radius tokens

enum RTRadius {
    static let badge: CGFloat        = 8    // cost badges, icon tile overlays
    static let iconTile: CGFloat     = 12   // workout sport tiles
    static let quickAction: CGFloat  = 14   // quick-action cards
    static let card: CGFloat         = 18   // cards, metric tiles, list groups
    static let onboardingTile: CGFloat = 22 // large sport selection tiles
    static let button: CGFloat       = 16   // CTA buttons
    static let pill: CGFloat         = 100  // connect pill, period selector
}

// MARK: - Elevation helpers

extension View {
    func rtCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
    }

    func rtCTAShadow(color: Color) -> some View {
        self.shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 8)
    }
}
