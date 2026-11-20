import SwiftUI
import UniformTypeIdentifiers

struct AppRulesTab: View {
    @Bindable var settings: AppSettings

    @State private var excludedSelection: Set<String> = []
    @State private var outputSelection: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Always type English in these apps").font(.headline)
                Text("Remote desktop and virtual machine apps (TeamViewer, AnyDesk, Screen Sharing, Parallels…) always get keys directly; type Vietnamese with the input method of the remote computer.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                List(settings.excludedApps, id: \.self, selection: $excludedSelection) { bundleID in
                    AppLabel(bundleID: bundleID)
                }
                .frame(minHeight: 110)
                HStack {
                    Button("Add App…") {
                        if let bundleID = chooseApp(), !settings.excludedApps.contains(bundleID) {
                            settings.excludedApps.append(bundleID)
                        }
                    }
                    Button("Remove") {
                        settings.excludedApps.removeAll { excludedSelection.contains($0) }
                        excludedSelection = []
                    }
                    .disabled(excludedSelection.isEmpty)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Output mode per app").font(.headline)
                List(settings.appOutputModes.keys.sorted(), id: \.self, selection: $outputSelection) { bundleID in
                    HStack {
                        AppLabel(bundleID: bundleID)
                        Spacer()
                        Picker("Output mode", selection: outputBinding(for: bundleID)) {
                            ForEach(OutputMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 260)
                    }
                }
                .frame(minHeight: 110)
                HStack {
                    Button("Add App…") {
                        if let bundleID = chooseApp(), settings.appOutputModes[bundleID] == nil {
                            settings.appOutputModes[bundleID] = .markedText
                        }
                    }
                    Button("Remove") {
                        for bundleID in outputSelection { settings.appOutputModes[bundleID] = nil }
                        outputSelection = []
                    }
                    .disabled(outputSelection.isEmpty)
                }
            }
        }
    }

    private func outputBinding(for bundleID: String) -> Binding<OutputMode> {
        Binding(
            get: { settings.appOutputModes[bundleID] ?? settings.outputMode },
            set: { settings.appOutputModes[bundleID] = $0 }
        )
    }

    private func chooseApp() -> String? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return Bundle(url: url)?.bundleIdentifier
    }
}

private struct AppLabel: View {
    let bundleID: String

    var body: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            Label {
                Text(FileManager.default.displayName(atPath: url.path))
            } icon: {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        } else {
            Text(bundleID)
        }
    }
}
