import Foundation
import os

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "moe.sei.kafra-desktop-assistant"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let drop = Logger(subsystem: subsystem, category: "drop")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
