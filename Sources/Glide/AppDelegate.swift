import AppKit
import ApplicationServices
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum PreferenceKey {
        static let isEnabled = "isEnabled"
        static let didConfigureLaunchAtLogin = "didConfigureLaunchAtLogin"
    }

    private let defaults = UserDefaults.standard
    private let scrollEventTap = ScrollEventTap()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private var enabledItem: NSMenuItem!
    private var permissionItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!

    private var isEnabled: Bool {
        get { defaults.bool(forKey: PreferenceKey.isEnabled) }
        set { defaults.set(newValue, forKey: PreferenceKey.isEnabled) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaults()
        configureMenu()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceApplicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        configureLaunchAtLoginOnFirstRun()
        startFilteringIfPossible(promptForPermission: true)
        refreshMenu()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func menuWillOpen(_ menu: NSMenu) {
        startFilteringIfPossible(promptForPermission: false)
        refreshMenu()
    }

    private func registerDefaults() {
        defaults.register(defaults: [PreferenceKey.isEnabled: true])
    }

    private func configureMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.up.arrow.down.circle", accessibilityDescription: "Glide")
            button.image?.isTemplate = true
            button.toolTip = "Glide"
        }

        let menu = NSMenu()
        menu.delegate = self

        enabledItem = NSMenuItem(title: "Reverse Mouse Scrolling", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.target = self
        menu.addItem(enabledItem)

        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        permissionItem = NSMenuItem(title: "Accessibility Permission", action: #selector(requestAccessibilityPermission), keyEquivalent: "")
        permissionItem.target = self
        menu.addItem(permissionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Glide", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func configureLaunchAtLoginOnFirstRun() {
        guard !defaults.bool(forKey: PreferenceKey.didConfigureLaunchAtLogin) else {
            return
        }

        guard SMAppService.mainApp.status == .notRegistered else {
            defaults.set(true, forKey: PreferenceKey.didConfigureLaunchAtLogin)
            return
        }

        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: PreferenceKey.didConfigureLaunchAtLogin)
        } catch {
            // The menu remains available so the user can retry or approve it later.
        }
    }

    private func startFilteringIfPossible(promptForPermission: Bool) {
        guard isEnabled else {
            scrollEventTap.stop()
            return
        }

        guard accessibilityIsGranted(prompt: promptForPermission) else {
            scrollEventTap.stop()
            return
        }

        _ = scrollEventTap.start()
    }

    private func accessibilityIsGranted(prompt: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func refreshMenu() {
        let hasAccessibilityPermission = accessibilityIsGranted(prompt: false)

        enabledItem.state = isEnabled ? .on : .off
        permissionItem.title = hasAccessibilityPermission
            ? "Accessibility: Granted"
            : "Grant Accessibility Permission…"
        permissionItem.isEnabled = !hasAccessibilityPermission

        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.title = "Launch at Login (Approval Needed)…"
            launchAtLoginItem.state = .mixed
        case .notFound, .notRegistered:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        @unknown default:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        }

        if let button = statusItem.button {
            let symbolName: String
            if !hasAccessibilityPermission {
                symbolName = "exclamationmark.circle"
            } else if isEnabled && scrollEventTap.isRunning {
                symbolName = "arrow.up.arrow.down.circle.fill"
            } else {
                symbolName = "arrow.up.arrow.down.circle"
            }
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Glide")
            button.image?.isTemplate = true
        }
    }

    @objc
    private func toggleEnabled() {
        isEnabled.toggle()
        startFilteringIfPossible(promptForPermission: isEnabled)
        refreshMenu()
    }

    @objc
    private func requestAccessibilityPermission() {
        _ = accessibilityIsGranted(prompt: true)
        startFilteringIfPossible(promptForPermission: false)
        refreshMenu()
    }

    @objc
    private func toggleLaunchAtLogin() {
        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister()
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
            case .notFound, .notRegistered:
                try SMAppService.mainApp.register()
            @unknown default:
                try SMAppService.mainApp.register()
            }
        } catch {
            showError(title: "Couldn’t update Launch at Login", error: error)
        }

        refreshMenu()
    }

    private func showError(title: String, error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    @objc
    private func workspaceApplicationDidActivate(_ notification: Notification) {
        guard isEnabled, !scrollEventTap.isRunning else {
            return
        }
        startFilteringIfPossible(promptForPermission: false)
        refreshMenu()
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
