import SwiftData
import SwiftUI

/// Ragnarok-Online-styled Notes window: the KDA memo store presented as an RO
/// panel with a note list and an inline editor. Backed by the SwiftData `Memo`
/// model (kept for data continuity; surfaced to the user as "Notes").
struct RONotesView: View {
    var onClose: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.updatedAt, order: .reverse) private var memos: [Memo]

    @State private var selectedID: UUID?
    @State private var draft: String = ""

    private var selected: Memo? {
        guard let selectedID else { return nil }
        return memos.first { $0.id == selectedID }
    }

    var body: some View {
        ROWindowChrome(title: "Notes", onClose: onClose) {
            VStack(spacing: 5) {
                noteList
                editor
                buttonRow
            }
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
        }
    }

    // MARK: - List

    private var noteList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(memos) { memo in
                    let firstLine = memo.body.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? ""
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.system(size: 11))
                            .foregroundStyle(ROTheme.textMuted)
                        Text(firstLine.isEmpty ? "(empty note)" : firstLine)
                            .font(ROTheme.bodyFont)
                            .foregroundStyle(ROTheme.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 6)
                        Text(memo.updatedAt, style: .date)
                            .font(ROTheme.smallFont)
                            .foregroundStyle(ROTheme.textMuted)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedID == memo.id ? ROTheme.selection : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { select(memo) }
                }
            }
            .padding(2)
        }
        .frame(height: 130)
        .background(ROSunkenBackground())
    }

    // MARK: - Editor

    private var editor: some View {
        TextEditor(text: $draft)
            .font(ROTheme.bodyFont)
            .foregroundStyle(ROTheme.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(4)
            .background(ROSunkenBackground())
            .disabled(selected == nil)
            .overlay(alignment: .topLeading) {
                if selected == nil {
                    Text("Select or create a note")
                        .font(ROTheme.smallFont)
                        .foregroundStyle(ROTheme.textMuted)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Buttons

    private var buttonRow: some View {
        HStack(spacing: 4) {
            Button("New") { createNote() }
                .buttonStyle(ROButtonStyle())
            Button("Save") { save() }
                .buttonStyle(ROButtonStyle())
                .disabled(selected == nil)
            Button("Delete") { deleteSelected() }
                .buttonStyle(ROButtonStyle())
                .disabled(selected == nil)
            Spacer()
            Text("\(memos.count) notes")
                .font(ROTheme.smallFont)
                .foregroundStyle(ROTheme.textMuted)
            Button("close") { onClose?() }
                .buttonStyle(ROButtonStyle())
        }
    }

    // MARK: - Actions

    private func select(_ memo: Memo) {
        selectedID = memo.id
        draft = memo.body
    }

    private func createNote() {
        let note = Memo(body: "")
        modelContext.insert(note)
        try? modelContext.save()
        selectedID = note.id
        draft = ""
    }

    private func save() {
        guard let selected else { return }
        selected.body = draft
        selected.updatedAt = Date()
        try? modelContext.save()
    }

    private func deleteSelected() {
        guard let selected else { return }
        modelContext.delete(selected)
        try? modelContext.save()
        selectedID = nil
        draft = ""
    }
}
