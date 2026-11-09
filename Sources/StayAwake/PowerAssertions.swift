import Foundation
import IOKit.pwr_mgt

/// Holds the same four power assertions as `caffeinate -dims`, in-process,
/// so there is no leftover `caffeinate` child to clean up.
final class PowerAssertions {
    /// Names are exactly what `pmset -g assertions` prints.
    static let types = [
        "PreventUserIdleDisplaySleep",  // -d  keep the display on
        "PreventUserIdleSystemSleep",   // -i  no idle system sleep
        "PreventDiskIdle",              // -m  keep disks from idling
        "PreventSystemSleep",           // -s  no system sleep (macOS honours this on AC power only)
    ]

    private var ids: [IOPMAssertionID] = []

    var isHeld: Bool { !ids.isEmpty }

    /// Takes all four assertions. Returns false (holding nothing) if any fails.
    @discardableResult
    func hold() -> Bool {
        guard ids.isEmpty else { return true }
        for type in Self.types {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Stay Awake is on" as CFString,
                &id
            )
            guard result == kIOReturnSuccess else {
                NSLog("StayAwake: could not create %@ assertion (IOReturn %d)", type, result)
                release()
                return false
            }
            ids.append(id)
        }
        return true
    }

    func release() {
        ids.forEach { IOPMAssertionRelease($0) }
        ids.removeAll()
    }

    /// Assertion types currently held by a process, straight from powerd.
    static func held(byPID pid: pid_t) -> [String] {
        var out: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&out) == kIOReturnSuccess,
              let byPID = out?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
        else { return [] }
        return (byPID[NSNumber(value: pid)] ?? []).compactMap { $0["AssertType"] as? String }
    }
}
