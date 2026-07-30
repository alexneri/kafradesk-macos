import AppKit
import SwiftData
import SwiftUI

final class MemoWindowController: NSWindowController {
    init(modelContainer: ModelContainer) {
        let window = ROWindowFactory.makeWindow(width: 360, height: 380, minWidth: 300, minHeight: 300)
        super.init(window: window)

        let rootView = RONotesView(onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })
        .environment(\.modelContext, modelContainer.mainContext)

        ROWindowFactory.install(rootView, in: window)
        ROWindowFactory.cascade(window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
