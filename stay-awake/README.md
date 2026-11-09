# Stay Awake

A menu-bar mug that keeps this Mac awake, modelled on Omarchy's coffee indicator.
It holds the same power assertions as `caffeinate -dims`, remembers whether it was
on or off, and comes back in that state after a reboot.

## Using it

| Action | Result |
| --- | --- |
| Click the mug | Toggle stay-awake |
| Right-click (or control-click) the mug | Menu: toggle, Open at Login, Quit |

- **Full mug with steam**: stay-awake is ON. The Mac will not sleep, dim, or start the screensaver from inactivity.
- **Dim, empty mug with no steam**: OFF. Normal macOS sleep settings apply.

First launch defaults to ON. The choice is saved on every toggle and re-applied at
launch, and the app registers itself as a login item the first time it runs from an
Applications folder. Quitting releases the assertions but keeps the saved choice.

### From a terminal

```sh
/Applications/StayAwake.app/Contents/MacOS/StayAwake --status   # what is it doing right now
/Applications/StayAwake.app/Contents/MacOS/StayAwake --toggle   # also --on / --off
pmset -g assertions | grep StayAwake                            # the system's view
```

`--on`, `--off` and `--toggle` talk to the running app; `--login-on` and `--login-off`
change the login item.

## What it does and does not prevent

While ON, the app holds four IOKit power assertions, the same set as `caffeinate -dims`:

| Assertion | `caffeinate` flag | Effect |
| --- | --- | --- |
| `PreventUserIdleDisplaySleep` | `-d` | Display stays on |
| `PreventUserIdleSystemSleep` | `-i` | No idle sleep |
| `PreventDiskIdle` | `-m` | Disks do not idle |
| `PreventSystemSleep` | `-s` | No system sleep, **on AC power only** |

Two limits, both macOS policy rather than something this app can change:

- **Closing the lid still puts the Mac to sleep.** This app is about sleep from
  inactivity. Do not count on it with the lid shut.
- **On battery, macOS ignores `PreventSystemSleep`**, exactly as it does for
  `caffeinate -s`. The other three still apply, so idle sleep is still prevented.

## Build and install

Needs the Xcode command-line tools (Swift 5.9 or later) and macOS 14 or later.

```sh
cd stay-awake
make            # build build/StayAwake.app
make install    # copy to /Applications/StayAwake.app and launch it
```

There is no Xcode project: `make` compiles `Sources/StayAwake/*.swift` with `swiftc`,
draws the icon, assembles the bundle, and ad-hoc signs it. To install elsewhere or
sign with a real identity:

```sh
make install DEST=~/Applications/StayAwake.app
make install IDENTITY="Apple Development: Your Name (TEAMID)"
```

The login item appears under **System Settings > General > Login Items & Extensions**.
If it is ever missing, turn on **Open at Login** from the mug's right-click menu.

## Uninstall

```sh
make uninstall
```

That removes the login item, quits the app, deletes `/Applications/StayAwake.app`,
and clears the saved state (`defaults delete com.zoan.StayAwake`).

## Layout

```
Sources/StayAwake/
  main.swift             entry point and the --flag command line
  AppDelegate.swift      the menu-bar item, clicks, and menu
  MugIcon.swift          the hand-drawn mug-and-steam menu-bar glyph
  PowerAssertions.swift  the four IOKit assertions
  LoginItem.swift        Open at Login (SMAppService)
  Preferences.swift      saved on/off choice (UserDefaults)
Resources/Info.plist     bundle metadata (LSUIElement: no Dock icon)
scripts/make-icon.swift  draws the app icon at build time
Makefile                 build / install / uninstall
```
