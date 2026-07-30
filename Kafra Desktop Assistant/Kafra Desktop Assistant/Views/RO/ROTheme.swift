import SwiftUI

/// Palette and reusable modifiers that recreate the classic Ragnarok Online
/// "basic interface" window skin (warm tan panels, beveled borders, pale title
/// bars) in native SwiftUI — the original VB6 app drew these procedurally, so
/// there are no bitmaps to load.
enum ROTheme {
    // Panel + chrome
    static let panelTop = Color(red: 0.945, green: 0.918, blue: 0.851)      // #F1EAD9
    static let panelBottom = Color(red: 0.902, green: 0.867, blue: 0.769)   // #E6DDC4
    static let titleTop = Color(red: 0.960, green: 0.937, blue: 0.878)      // #F5EFE0
    static let titleBottom = Color(red: 0.894, green: 0.851, blue: 0.737)   // #E4D8BC

    static let borderDark = Color(red: 0.478, green: 0.416, blue: 0.310)    // #7A6A4F
    static let bevelLight = Color(red: 1.0, green: 0.984, blue: 0.941)       // #FFFBF0
    static let bevelShadow = Color(red: 0.718, green: 0.663, blue: 0.529)   // #B7A987

    // Text
    static let textPrimary = Color(red: 0.180, green: 0.165, blue: 0.133)   // #2E2A22
    static let textTitle = Color(red: 0.290, green: 0.231, blue: 0.149)     // #4A3B26
    static let textMuted = Color(red: 0.443, green: 0.408, blue: 0.322)     // #716852
    static let qtyGreen = Color(red: 0.176, green: 0.408, blue: 0.180)      // #2D682E

    // Accents
    static let systemDot = Color(red: 0.243, green: 0.435, blue: 0.690)     // #3E6FB0
    static let selection = Color(red: 0.780, green: 0.847, blue: 0.941)     // #C7D8F0
    static let listBackground = Color(red: 0.976, green: 0.961, blue: 0.914) // #F9F5E9

    static let titleFont = Font.system(size: 12, weight: .semibold)
    static let bodyFont = Font.system(size: 12, weight: .regular)
    static let smallFont = Font.system(size: 11, weight: .regular)
}

/// Outer window panel: tan fill, 1px dark border with a light inner bevel line.
struct ROPanelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [ROTheme.panelTop, ROTheme.panelBottom],
                           startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 1)
                .inset(by: 0.5)
                .stroke(ROTheme.bevelLight, lineWidth: 1)
                .padding(1)
            RoundedRectangle(cornerRadius: 2)
                .inset(by: 0.5)
                .stroke(ROTheme.borderDark, lineWidth: 1)
        }
    }
}

/// A sunken content area (item list background) with an inset bevel.
struct ROSunkenBackground: View {
    var body: some View {
        ZStack {
            ROTheme.listBackground
            Rectangle()
                .strokeBorder(ROTheme.bevelShadow, lineWidth: 1)
            Rectangle()
                .strokeBorder(ROTheme.bevelLight.opacity(0.6), lineWidth: 1)
                .padding(1)
        }
    }
}

/// Small beveled RO push button (e.g. "close").
struct ROButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ROTheme.smallFont)
            .foregroundStyle(ROTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                ZStack {
                    LinearGradient(
                        colors: configuration.isPressed
                            ? [ROTheme.titleBottom, ROTheme.titleTop]
                            : [ROTheme.titleTop, ROTheme.titleBottom],
                        startPoint: .top, endPoint: .bottom)
                    Rectangle().strokeBorder(ROTheme.borderDark, lineWidth: 1)
                    Rectangle().strokeBorder(ROTheme.bevelLight.opacity(0.8), lineWidth: 1).padding(1)
                }
            )
            .contentShape(Rectangle())
    }
}

/// Small circular title-bar pip (minimize / close), beveled ring with a glyph.
struct ROTitlePip: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [ROTheme.titleTop, ROTheme.titleBottom],
                                         startPoint: .top, endPoint: .bottom))
                Circle().strokeBorder(ROTheme.borderDark, lineWidth: 1)
                Image(systemName: systemName)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(ROTheme.textTitle)
            }
            .frame(width: 13, height: 13)
        }
        .buttonStyle(.plain)
    }
}
