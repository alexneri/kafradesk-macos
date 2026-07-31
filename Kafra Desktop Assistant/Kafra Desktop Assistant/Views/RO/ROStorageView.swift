import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Ragnarok-Online-styled Storage window: the KDA file store presented like the
/// classic Kafra Storage panel (vertical Item tab, item rows, filter/search bar,
/// count, and an RO "close" button). All behavior is delegated to StorageService.
struct ROStorageView: View {
    var onClose: (() -> Void)?

    @StateObject private var storageService = StorageService()
    @State private var selectedItem: StorageItem?
    @State private var isDropTarget = false
    @State private var searchText = ""
    @State private var showNewFolderPrompt = false
    @State private var newFolderName = ""

    private var visibleItems: [StorageItem] {
        guard !searchText.isEmpty else { return storageService.items }
        return storageService.items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ROWindowChrome(title: "Storage", onClose: onClose) {
            HStack(spacing: 5) {
                verticalTab
                VStack(spacing: 5) {
                    itemList
                    bottomBar
                }
            }
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 240, maxHeight: .infinity)
        }
        .onAppear { storageService.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            storageService.refresh()
        }
        .alert("New Folder", isPresented: $showNewFolderPrompt) {
            TextField("Folder name", text: $newFolderName)
            Button("Create") {
                storageService.createFolder(named: newFolderName)
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) { newFolderName = "" }
        } message: {
            Text("Enter a name for the new folder.")
        }
    }

    // MARK: - Left vertical tab

    private var verticalTab: some View {
        Text("Item")
            .font(ROTheme.smallFont)
            .foregroundStyle(ROTheme.textTitle)
            .rotationEffect(.degrees(-90))
            .fixedSize()
            .frame(width: 16)
            .frame(maxHeight: .infinity)
            .background(
                ZStack {
                    LinearGradient(colors: [ROTheme.titleTop, ROTheme.titleBottom],
                                   startPoint: .leading, endPoint: .trailing)
                    Rectangle().strokeBorder(ROTheme.bevelShadow, lineWidth: 1)
                }
            )
    }

    // MARK: - Item list

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(visibleItems) { item in
                    itemRow(item)
                }
            }
            .padding(2)
        }
        .background(ROSunkenBackground())
        .overlay(
            Rectangle()
                .strokeBorder(isDropTarget ? ROTheme.systemDot : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func itemRow(_ item: StorageItem) -> some View {
        HStack(spacing: 7) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 12))
                .foregroundStyle(item.isDirectory ? ROTheme.systemDot : ROTheme.textMuted)
                .frame(width: 16)
            Text(item.name)
                .font(ROTheme.bodyFont)
                .foregroundStyle(ROTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 6)
            if let size = item.size, !item.isDirectory {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(ROTheme.smallFont)
                    .foregroundStyle(ROTheme.qtyGreen)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selectedItem == item ? ROTheme.selection : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { storageService.open(item) }
        .onTapGesture { selectedItem = item }
        .contextMenu {
            Button("Open") { storageService.open(item) }
            Button("Reveal in Finder") { storageService.reveal(item) }
            Divider()
            Button("Delete", role: .destructive) { storageService.delete(item) }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                iconButton("folder.badge.plus", help: "New Folder") { showNewFolderPrompt = true }
                iconButton("arrow.up.right.square", help: "Open") {
                    if let selectedItem { storageService.open(selectedItem) }
                }
                iconButton("magnifyingglass.circle", help: "Reveal in Finder") {
                    if let selectedItem { storageService.reveal(selectedItem) }
                }
                iconButton("trash", help: "Delete") {
                    if let selectedItem { storageService.delete(selectedItem) }
                }
                Spacer()
                Text("\(storageService.items.count) items")
                    .font(ROTheme.smallFont)
                    .foregroundStyle(ROTheme.textMuted)
            }

            HStack(spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 9))
                        .foregroundStyle(ROTheme.textMuted)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(ROTheme.smallFont)
                        .foregroundStyle(ROTheme.textPrimary)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(ROSunkenBackground())

                Button("close") { onClose?() }
                    .buttonStyle(ROButtonStyle())
            }
        }
    }

    private func iconButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .frame(width: 16, height: 14)
        }
        .buttonStyle(ROButtonStyle())
        .help(help)
    }

    // MARK: - Drop

    private func handleDrop(providers: [NSItemProvider]) {
        Task {
            let urls = await DropHandler.loadFileURLs(from: providers)
            guard !urls.isEmpty else { return }
            let handler = DropHandler()
            await handler.handleDrop(urls: urls, window: NSApp.keyWindow)
            storageService.refresh()
        }
    }
}
