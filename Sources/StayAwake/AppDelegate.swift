import AppKit
import ServiceManagement

/// The menu-bar mug. Left-click toggles; right-click (or control-click) opens the menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let assertions = PowerAssertions()
    private let menu = NSMenu()
    private let stayAwakeItem = NSMenuItem(title: "Stay Awake", action: #selector(toggleStayAwake), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleLoginItem), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "StayAwake"
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        buildMenu()

        LoginItem.registerOnFirstLaunch()
        setStayAwake(Preferences.stayAwake)  // restore the last choice (ON on first launch)

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleRemoteCommand(_:)),
            name: RemoteCommand.notification, object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        assertions.release()  // the saved choice is kept, so the next launch restores it
    }

    // MARK: Stay awake

    private func setStayAwake(_ wanted: Bool) {
        Preferences.stayAwake = wanted
        if wanted {
            assertions.hold()
        } else {
            assertions.release()
        }
        refreshIcon()
    }

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        let on = assertions.isHeld
        let image = NSImage(
            systemSymbolName: on ? "mug.fill" : "mug",
            accessibilityDescription: on ? "Stay Awake is on" : "Stay Awake is off"
        )
        image?.isTemplate = true
        button.image = image
        button.appearsDisabled = !on  // dim the empty mug
        button.toolTip = on
            ? "Stay Awake is on — click to allow sleep"
            : "Stay Awake is off — click to keep this Mac awake"
    }

    // MARK: Clicks

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsMenu {
            // Attach the menu just for this click so a plain click stays a toggle.
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleStayAwake()
        }
    }

    @objc private func toggleStayAwake() {
        setStayAwake(!assertions.isHeld)
    }

    @objc private func handleRemoteCommand(_ note: Notification) {
        switch note.object as? String {
        case "on": setStayAwake(true)
        case "off": setStayAwake(false)
        case "toggle": toggleStayAwake()
        default: break
        }
    }

    // MARK: Menu

    private func buildMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        stayAwakeItem.target = self
        loginItem.target = self

        menu.addItem(stayAwakeItem)
        menu.addItem(note("Keeps the display and system awake while idle"))
        menu.addItem(note("Closing the lid still puts the Mac to sleep"))
        menu.addItem(.separator())
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Stay Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func note(_ text: String) -> NSMenuItem {
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize),
        ])
        return item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        stayAwakeItem.state = assertions.isHeld ? .on : .off
        let status = LoginItem.status
        loginItem.state = status == .enabled ? .on : .off
        loginItem.title = status == .requiresApproval ? "Open at Login (approve in System Settings…)" : "Open at Login"
    }

    @objc private func toggleLoginItem() {
        let status = LoginItem.status
        do {
            try LoginItem.setEnabled(status != .enabled && status != .requiresApproval)
        } catch {
            NSLog("StayAwake: login item change failed: %@", error.localizedDescription)
        }
        if status == .requiresApproval || LoginItem.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
