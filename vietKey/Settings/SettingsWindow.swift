import AppKit
import Observation
import SwiftUI

enum SettingsTab: Hashable {
    case general, typing, macros, apps, converter
}

@Observable
final class SettingsNavigation {
    var selectedTab: SettingsTab = .general
}

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private let navigation = SettingsNavigation()
    private var window: NSWindow?

    func show(tab: SettingsTab) {
        navigation.selectedTab = tab
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(settings: .shared, navigation: navigation))
            let window = NSWindow(contentViewController: hosting)
            window.title = String(localized: "VIET Settings")
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if !InputSourceInstaller.isRunningFromInstallLocation {
            NSApp.terminate(nil)
        }
    }
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            GeneralTab(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            InputMethodTab(settings: settings)
                .tabItem { Label("Typing", systemImage: "keyboard") }
                .tag(SettingsTab.typing)
            MacroTab(settings: settings)
                .tabItem { Label("Macros", systemImage: "text.badge.plus") }
                .tag(SettingsTab.macros)
            AppRulesTab(settings: settings)
                .tabItem { Label("Apps", systemImage: "square.grid.2x2") }
                .tag(SettingsTab.apps)
            ConverterTab()
                .tabItem { Label("Converter", systemImage: "arrow.left.arrow.right") }
                .tag(SettingsTab.converter)
        }
        .frame(width: 600, height: 460)
        .padding()
    }
}
