import SwiftData
import SwiftUI

struct MemoEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let memo: Memo?

    @State private var bodyText: String
    @State private var showDeleteAlert = false

    init(memo: Memo?) {
        self.memo = memo
        _bodyText = State(initialValue: memo?.body ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $bodyText)
                .font(.body)
                .frame(minHeight: 180)
                .accessibilityLabel("Memo text")

            HStack {
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)

                if memo != nil {
                    Button("Delete") {
                        showDeleteAlert = true
                    }
                    .keyboardShortcut(.delete, modifiers: [.command])
                }

                Spacer()
            }
        }
        .padding(16)
        .navigationTitle(memo == nil ? "New Memo" : "Edit Memo")
        .alert("Delete memo?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteMemo()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func save() {
        if let memo {
            memo.body = bodyText
            memo.updatedAt = Date()
        } else {
            let newMemo = Memo(body: bodyText)
            modelContext.insert(newMemo)
        }

        try? modelContext.save()
        if memo == nil {
            dismiss()
        }
    }

    private func deleteMemo() {
        if let memo {
            modelContext.delete(memo)
            try? modelContext.save()
            dismiss()
        }
    }
}
