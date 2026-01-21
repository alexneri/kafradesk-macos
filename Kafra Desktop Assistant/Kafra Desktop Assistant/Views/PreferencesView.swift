import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var catalog: CharacterCatalog

    var body: some View {
        Form {
            Section(header: Text("Mascot")) {
                Toggle("Show mascot", isOn: $appState.isMascotVisible)
                    .accessibilityLabel("Show mascot")

                Toggle("Always on top", isOn: $appState.alwaysOnTop)
                    .accessibilityLabel("Always on top")

                Toggle("Enable animations", isOn: $appState.animationsEnabled)
                    .accessibilityLabel("Enable animations")
            }

            Section(header: Text("Edition")) {
                Picker("Edition", selection: $appState.selectedEdition) {
                    ForEach(CharacterEdition.allCases) { edition in
                        Text(edition.displayName).tag(edition)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Edition")
                .onChange(of: appState.selectedEdition) { _, newEdition in
                    let fallback = catalog.defaultCharacter(for: newEdition)
                    if let fallback {
                        appState.selectedCharacterID = fallback.id
                    }
                }

                Picker("Character", selection: $appState.selectedCharacterID) {
                    ForEach(catalog.characters(for: appState.selectedEdition)) { character in
                        Text(character.displayName).tag(character.id)
                    }
                }
                .accessibilityLabel("Character")
            }

            Section {
                Button("Reset window position") {
                    appState.windowPosition = nil
                }
                .accessibilityLabel("Reset window position")
            }
        }
        .frame(width: 360)
        .padding(12)
    }
}
