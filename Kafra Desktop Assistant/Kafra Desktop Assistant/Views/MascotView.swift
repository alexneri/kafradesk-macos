import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MascotView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var catalog: CharacterCatalog
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isDropTarget = false
    @State private var isBlinking = false

    private var currentCharacter: CharacterAsset? {
        catalog.character(id: appState.selectedCharacterID)
            ?? catalog.defaultCharacter(for: appState.selectedEdition)
    }

    var body: some View {
        Group {
            if let character = currentCharacter {
                let usesAlternate = character.blinkImageName != nil
                let imageName = isBlinking ? (character.blinkImageName ?? character.imageName) : character.imageName
                if let image = CharacterImageProvider.image(named: imageName) {
                    Image(nsImage: image)
                        .interpolation(.high)
                        .opacity(isBlinking && !usesAlternate ? 0.9 : 1.0)
                        .accessibilityLabel("\(character.displayName) mascot")
                } else {
                    Text(character.displayName)
                        .font(.headline)
                        .padding(12)
                }
            } else {
                Text("No Character")
                    .font(.headline)
                    .padding(20)
            }
        }
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
            return true
        }
        .task(id: appState.animationsEnabled || reduceMotion) {
            await runBlinkLoop()
        }
        .onChange(of: appState.selectedCharacterID) { _, _ in
            isBlinking = false
        }
    }

    private func runBlinkLoop() async {
        guard appState.animationsEnabled && !reduceMotion else {
            await MainActor.run { isBlinking = false }
            return
        }

        while !Task.isCancelled {
            let delay = UInt64.random(in: 3_000_000_000...7_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await MainActor.run { isBlinking = true }
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run { isBlinking = false }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []

            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) {
                        if let url = item as? URL {
                            urls.append(url)
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            urls.append(url)
                        }
                    }
                }
            }

            guard !urls.isEmpty else { return }

            let handler = DropHandler()
            await handler.handleDrop(urls: urls, window: NSApp.keyWindow)
        }
    }
}
