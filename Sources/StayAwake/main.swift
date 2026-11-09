import AppKit

/// How `StayAwake --toggle` (etc.) reaches the running menu-bar app.
enum RemoteCommand {
    static let notification = Notification.Name("\(bundleID).command")

    static func post(_ command: String) {
        DistributedNotificationCenter.default().postNotificationName(
            notification, object: command, userInfo: nil, deliverImmediately: true
        )
    }
}

func otherRunningInstance() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        .first { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
}

/// A tiny command-line face for scripts, the analogue of `omarchy-toggle-idle`.
enum CLI {
    static let usage = """
        usage: StayAwake [--on | --off | --toggle | --status | --login-on | --login-off]
        With no arguments, runs the menu-bar app.
        """

    static func run(_ flag: String) -> Int32 {
        switch flag {
        case "--on", "--off", "--toggle":
            guard otherRunningInstance() != nil else {
                print("Stay Awake isn't running. Open the app first.")
                return 1
            }
            RemoteCommand.post(String(flag.dropFirst(2)))
            Thread.sleep(forTimeInterval: 0.3)  // let the app apply it before reporting
            printStatus()
        case "--status":
            printStatus()
        case "--login-on", "--login-off":
            do {
                try LoginItem.setEnabled(flag == "--login-on")
            } catch {
                print("Could not change the login item: \(error.localizedDescription)")
                return 1
            }
            printStatus()
        case "--help":
            print(usage)
        default:
            print(usage)
            return 64
        }
        return 0
    }

    static func printStatus() {
        if let app = otherRunningInstance() {
            let held = PowerAssertions.held(byPID: app.processIdentifier)
            print("App:           running (pid \(app.processIdentifier))")
            print("Stay Awake:    \(held.isEmpty ? "OFF" : "ON")")
            print("Assertions:    \(held.isEmpty ? "none" : held.sorted().joined(separator: ", "))")
        } else {
            print("App:           not running")
        }
        print("Saved choice:  \(Preferences.stayAwake ? "on" : "off") (re-applied at launch)")
        print("Open at Login: \(LoginItem.statusText)")
    }
}

Preferences.registerDefaults()

if let flag = CommandLine.arguments.dropFirst().first, flag.hasPrefix("--") {
    exit(CLI.run(flag))
}

// One mug is enough: if a copy is already running, leave it be.
if otherRunningInstance() != nil {
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()  // kept alive by this scope: run() never returns
    app.delegate = delegate
    app.setActivationPolicy(.accessory)  // no Dock icon (Info.plist also sets LSUIElement)
    app.run()
}
