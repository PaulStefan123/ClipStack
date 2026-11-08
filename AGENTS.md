# Instructions for AI coding assistants (GitHub Copilot, Claude Code, Cursor, etc.)

This folder contains **ClipStack**, a small macOS menu-bar clipboard manager written in Swift.
It's a Swift Package with no third-party dependencies and no network access.

## If the user asks you to install ClipStack

1. Make sure you're on macOS 13 or newer: `sw_vers -productVersion`.
2. From this folder, run:

   ```bash
   chmod +x install.sh build.sh uninstall.sh && ./install.sh
   ```

   - The script checks the Mac and builds a universal app with `swift build`. It installs the app
     to `/Applications`, or to `~/Applications` if `/Applications` isn't writable, then launches it.
   - Xcode is **not** required, only Apple's Command Line Tools. If they're missing, the script
     opens Apple's installer and exits. Tell the user to click **Install**, wait for it to finish,
     then run `./install.sh` again.
   - The first build takes about 1–2 minutes. Use a long timeout and don't interrupt it.
3. Tell the user to finish this **one step themselves**. A script can't do it, because macOS
   blocks automation of privacy permissions on purpose:
   > When macOS asks "ClipStack would like to control this computer using accessibility
   > features", click **Open System Settings** and turn on **ClipStack**. Then quit ClipStack
   > from its menu bar icon and open it again.
4. Explain how to use it: **⌥⌘V** opens the list, **↑/↓** choose an item, **Return** pastes it.
   Settings are under the menu bar icon › **Settings…**.

## Don't

- Don't use `sudo`. Nothing here needs it.
- Don't try to change the Accessibility permission (TCC) yourself, or edit system
  databases. Only the user can grant it.
- Don't change the source code to "fix" warnings. The app builds as is.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `xcrun: error` or `swift: command not found` | Run `xcode-select --install`, wait for it to finish, then run `./install.sh` again. |
| The build fails with a stale cache error | `rm -rf .build build && ./install.sh` |
| Pasting does nothing, or the permission prompt keeps returning | In System Settings › Privacy & Security › Accessibility, remove ClipStack with **–**, add the installed app again with **+**, turn it on, and restart ClipStack. |
| ⌥⌘V does nothing | Another app owns that shortcut. Pick a different one in ClipStack › Settings…. |

## Uninstall

```bash
./uninstall.sh
```

## Project layout

- `Sources/ClipStack/`: app code (AppKit and SwiftUI)
- `build.sh`: builds `build/ClipStack.app` (ad-hoc signed) and `dist/ClipStack-<version>.zip`
- `install.sh` / `uninstall.sh`: one-step install and removal
- `README.md`: full documentation for humans
