import SwiftData
import SwiftUI

struct MemoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Memo.updatedAt, order: .reverse) private var memos: [Memo]

    @State private var selectedMemoID: UUID?
    @State private var isPresentingNew = false

    private var selectedMemo: Memo? {
        guard let selectedMemoID else { return nil }
        return memos.first { $0.id == selectedMemoID }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMemoID) {
                ForEach(memos) { memo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.body.isEmpty ? "(Empty memo)" : memo.body)
                            .lineLimit(1)
                            .font(.headline)
                        Text(memo.updatedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(memo.id)
                }
                .onDelete(perform: deleteMemos)
            }
            .navigationTitle("Memos")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNew = true
                    } label: {
                        Label("New Memo", systemImage: "plus")
                    }
                    .accessibilityLabel("New Memo")
                }
            }
        } detail: {
            if let memo = selectedMemo {
                MemoEditorView(memo: memo)
            } else {
                Text("Select a memo")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            MemoEditorView(memo: nil)
        }
    }

    private func deleteMemos(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(memos[index])
        }
        try? modelContext.save()
    }
}
