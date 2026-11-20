import AppKit
import InputMethodKit
import VietEngine

enum IMMenu {
    static func make(target: VKInputController, session: InputSession) -> NSMenu {
        let settings = session.settings
        let menu = NSMenu()

        let methods = NSMenu()
        for kind in InputMethodKind.allCases {
            let item = NSMenuItem(title: kind.displayName, action: #selector(VKInputController.selectInputMethod(_:)), keyEquivalent: "")
            item.representedObject = kind.rawValue
            item.state = settings.inputMethod == kind ? .on : .off
            item.target = target
            methods.addItem(item)
        }
        let methodsItem = NSMenuItem(title: String(localized: "Input Method"), action: nil, keyEquivalent: "")
        methodsItem.submenu = methods
        menu.addItem(methodsItem)

        menu.addItem(toggle(String(localized: "Modern Tone Placement (hoà, thuỷ)"),
                            on: settings.toneStyle == .new,
                            action: #selector(VKInputController.toggleToneStyle(_:)), target: target))
        menu.addItem(toggle(String(localized: "Restore Non-Vietnamese Words"),
                            on: settings.spellCheck,
                            action: #selector(VKInputController.toggleSpellCheck(_:)), target: target))
        menu.addItem(toggle(String(localized: "Enable Macros"),
                            on: settings.macrosEnabled,
                            action: #selector(VKInputController.toggleMacros(_:)), target: target))

        if let bundleID = session.clientBundleID {
            menu.addItem(.separator())
            menu.addItem(toggle(String(localized: "Always English in This App"),
                                on: settings.excludedApps.contains(bundleID),
                                action: #selector(VKInputController.toggleExcludeCurrentApp(_:)), target: target))
        }

        menu.addItem(.separator())
        let quickInput = NSMenuItem(title: String(localized: "Quick Input…"), action: #selector(VKInputController.openQuickInput(_:)), keyEquivalent: "")
        quickInput.target = target
        menu.addItem(quickInput)
        let converter = NSMenuItem(title: String(localized: "Convert Clipboard…"), action: #selector(VKInputController.openConverter(_:)), keyEquivalent: "")
        converter.target = target
        menu.addItem(converter)
        let settingsItem = NSMenuItem(title: String(localized: "VIET Settings…"), action: #selector(VKInputController.openSettings(_:)), keyEquivalent: "")
        settingsItem.target = target
        menu.addItem(settingsItem)
        return menu
    }

    static func item(from sender: Any?) -> NSMenuItem? {
        if let item = sender as? NSMenuItem { return item }
        return (sender as? NSDictionary)?[kIMKCommandMenuItemName as Any] as? NSMenuItem
    }

    private static func toggle(_ title: String, on: Bool, action: Selector, target: AnyObject) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.state = on ? .on : .off
        item.target = target
        return item
    }
}
