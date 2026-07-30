import AppKit
import SwiftUI

final class StorageWindowController: NSWindowController {
    init() {
        let window = ROWindowFactory.makeWindow(width: 400, height: 360, minWidth: 320, minHeight: 260)
        super.init(window: window)

        let rootView = ROStorageView(onClose: { [weak self] in
            self?.window?.orderOut(nil)
        })
        ROWindowFactory.install(rootView, in: window)
        ROWindowFactory.cascade(window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
