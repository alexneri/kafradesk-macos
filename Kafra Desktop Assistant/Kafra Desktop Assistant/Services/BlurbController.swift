import AppKit
import Foundation

enum BlurbIcon {
    case success
    case warning
    case info

    var systemName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

final class BlurbController {
    static let shared = BlurbController()

    private var windowController: BlurbWindowController?
    private var dismissWorkItem: DispatchWorkItem?

    func show(message: String, icon: BlurbIcon, duration: TimeInterval) {
        if windowController == nil {
            windowController = BlurbWindowController()
        }

        windowController?.update(message: message, icon: icon)
        windowController?.showWindow(nil)
        windowController?.window?.orderFrontRegardless()

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.windowController?.window?.orderOut(nil)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}
