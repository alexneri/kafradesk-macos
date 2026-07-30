import SwiftData
import SwiftUI

/// Ragnarok-Online-styled Tasks window: a small task tracker (add, check off,
/// delete) backed by the SwiftData `TaskItem` model.
struct ROTasksView: View {
    var onClose: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .forward)
    private var tasks: [TaskItem]

    @State private var newTitle: String = ""

    private var openCount: Int { tasks.filter { !$0.isDone }.count }

    var body: some View {
        ROWindowChrome(title: "Tasks", onClose: onClose) {
            VStack(spacing: 5) {
                addRow
                taskList
                bottomBar
            }
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 240, maxHeight: .infinity)
        }
    }

    // MARK: - Add

    private var addRow: some View {
        HStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 9))
                    .foregroundStyle(ROTheme.textMuted)
                TextField("New task", text: $newTitle)
                    .textFieldStyle(.plain)
                    .font(ROTheme.smallFont)
                    .foregroundStyle(ROTheme.textPrimary)
                    .onSubmit(addTask)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(ROSunkenBackground())

            Button("Add") { addTask() }
                .buttonStyle(ROButtonStyle())
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
            .padding(2)
        }
        .background(ROSunkenBackground())
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 7) {
            Button {
                toggle(task)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [ROTheme.titleTop, ROTheme.titleBottom],
                                             startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 2).strokeBorder(ROTheme.borderDark, lineWidth: 1)
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(ROTheme.qtyGreen)
                    }
                }
                .frame(width: 13, height: 13)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .font(ROTheme.bodyFont)
                .foregroundStyle(task.isDone ? ROTheme.textMuted : ROTheme.textPrimary)
                .strikethrough(task.isDone, color: ROTheme.textMuted)
                .lineLimit(1)

            Spacer(minLength: 6)

            Button {
                delete(task)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(ROTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Delete task")
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    // MARK: - Bottom

    private var bottomBar: some View {
        HStack(spacing: 4) {
            if tasks.contains(where: { $0.isDone }) {
                Button("Clear Done") { clearDone() }
                    .buttonStyle(ROButtonStyle())
            }
            Spacer()
            Text("\(openCount) open / \(tasks.count) total")
                .font(ROTheme.smallFont)
                .foregroundStyle(ROTheme.textMuted)
            Button("close") { onClose?() }
                .buttonStyle(ROButtonStyle())
        }
    }

    // MARK: - Actions

    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        modelContext.insert(TaskItem(title: title))
        try? modelContext.save()
        newTitle = ""
    }

    private func toggle(_ task: TaskItem) {
        task.isDone.toggle()
        task.completedAt = task.isDone ? Date() : nil
        try? modelContext.save()
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func clearDone() {
        for task in tasks where task.isDone {
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
}
