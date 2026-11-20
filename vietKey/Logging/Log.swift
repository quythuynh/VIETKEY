import os

enum Log {
    private static let subsystem = AppIdentity.bundleID

    static let app = Logger(subsystem: subsystem, category: "app")
    static let input = Logger(subsystem: subsystem, category: "input")
}
