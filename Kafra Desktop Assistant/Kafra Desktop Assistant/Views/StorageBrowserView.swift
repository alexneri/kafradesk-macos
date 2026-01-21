import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct StorageBrowserView: View {
    @StateObject private var storageService = StorageService()
    @State private var selectedItem: StorageItem?
    @State private var isDropTarget = false
    @State private var showNewFolderPrompt = false
    @State private var newFolderName = ""

    var body: some View {
        VStack {
            List(selection: $selectedItem) {
                ForEach(storageService.items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.isDirectory ? "folder" : "doc")
                            .foregroundColor(item.isDirectory ? .accentColor : .secondary)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .lineLimit(1)
                            if let modified = item.modifiedDate {
                                Text(modified, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if let size = item.size, !item.isDirectory {
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .contextMenu {
                        Button("Open") { storageService.open(item) }
                        Button("Reveal in Finder") { storageService.reveal(item) }
                        Divider()
                        Button("Delete", role: .destructive) { storageService.delete(item) }
                    }
                    .tag(item)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
                handleDrop(providers: providers)
                return true
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDropTarget ? Color.accentColor : Color.clear, lineWidth: 2)
                    .padding(6)
            )
        }
        .navigationTitle("Storage")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showNewFolderPrompt = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                Button {
                    if let selectedItem {
                        storageService.open(selectedItem)
                    }
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
                .disabled(selectedItem == nil)
                Button {
                    if let selectedItem {
                        storageService.reveal(selectedItem)
                    }
                } label: {
                    Label("Reveal", systemImage: "finder")
                }
                .disabled(selectedItem == nil)
                Button(role: .destructive) {
                    if let selectedItem {
                        storageService.delete(selectedItem)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedItem == nil)
            }
        }
        .onAppear {
            storageService.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            storageService.refresh()
        }
        .alert("New Folder", isPresented: $showNewFolderPrompt) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                storageService.createFolder(named: newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
        } message: {
            Text("Enter a name for the new folder.")
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
            storageService.refresh()
        }
    }
}
