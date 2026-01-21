import SwiftUI

struct AboutView: View {
    private let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Kafra Desktop Assistant"
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundColor(.accentColor)

            Text(appName)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(appVersion)")
                .foregroundColor(.secondary)

            Text("Fan work inspired by Ragnarok Online.\nOriginal art and characters belong to their respective owners. Original Windows app by EnderSoft. Ported by SG Research.\n\nMade with ❤️ in SwiftUI by [Alex Neri (Crosse_)](https://sei.moe)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 360)
    }
}
