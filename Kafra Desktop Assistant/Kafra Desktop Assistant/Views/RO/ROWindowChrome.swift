import SwiftUI

/// Reusable Ragnarok-Online-style window frame: a pale title bar (system dot,
/// title text, minimize/close pips) atop a beveled tan panel that hosts
/// arbitrary content. Meant to sit inside a borderless NSWindow.
struct ROWindowChrome<Content: View>: View {
    let title: String
    var onMinimize: (() -> Void)?
    var onClose: (() -> Void)?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            content()
                .padding(6)
        }
        .background(ROPanelBackground())
        .overlay(alignment: .bottomTrailing) {
            ROResizeGrip().padding(3)
        }
    }

    private var titleBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ROTheme.systemDot)
                .frame(width: 9, height: 9)
                .overlay(Circle().strokeBorder(ROTheme.borderDark.opacity(0.6), lineWidth: 0.5))

            Text(title)
                .font(ROTheme.titleFont)
                .foregroundStyle(ROTheme.textTitle)

            Spacer(minLength: 8)

            if let onMinimize {
                ROTitlePip(systemName: "minus", action: onMinimize)
            }
            if let onClose {
                ROTitlePip(systemName: "xmark", action: onClose)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            ZStack {
                LinearGradient(colors: [ROTheme.titleTop, ROTheme.titleBottom],
                               startPoint: .top, endPoint: .bottom)
                VStack {
                    Spacer()
                    Rectangle().fill(ROTheme.bevelShadow).frame(height: 1)
                }
            }
        )
        // The title bar is the drag handle for the borderless window.
        .contentShape(Rectangle())
    }
}
