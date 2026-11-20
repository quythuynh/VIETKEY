import Foundation

enum AppIdentity {
    static let bundleID = Bundle.main.bundleIdentifier ?? "htq.inputmethod.vietKey"
    static let vietnameseModeID = bundleID + ".vi"
    static let englishModeID = bundleID + ".en"
    static let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
        ?? "vietKey_Connection"
    static let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
