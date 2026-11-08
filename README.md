# ClipStack

A small, local clipboard manager for macOS, inspired by [Pastebot](https://tapbots.com/pastebot/).

- **⌘C**: copy as usual. ClipStack keeps your last **10** text copies, newest first.
- **⌥⌘V** (Option-Command-V): opens the clipboard panel. You can change this shortcut in Settings.
- **↑ / ↓**: move through the list.
- **↩ Return**: pastes the selected item into the app you were using.
- **1–9, 0**: paste that row straight away.
- **⌫ Delete**: removes the selected item. **Esc** or clicking elsewhere closes the panel.
- Opens automatically when you log in, and lives in the menu bar (clipboard icon). There's no Dock icon.
- **Settings** (menu bar icon › **Settings…**): change the shortcut, turn open-at-login on or off, and choose how long copies are kept (1 hour, 1 day, 1 week, 30 days, or until newer copies replace them).

Everything stays on your Mac. There's no network access, and the history is stored in
`~/Library/Application Support/ClipStack/history.json`, which only your user account can read.
Password managers that mark copies as concealed (1Password, Bitwarden, Keychain, etc.) aren't recorded.

Requires **macOS 13 Ventura or later**. Runs natively on Apple Silicon and Intel Macs.

---

## Install (from the zip you were sent)

1. Unzip `ClipStack-1.0.0.zip` and drag **ClipStack.app** into your **Applications** folder.
2. The app isn't signed with a paid Apple Developer certificate, so macOS blocks it the
   first time. Run this once in Terminal to clear the download flag:

   ```bash
   xattr -dr com.apple.quarantine /Applications/ClipStack.app
   ```

   You can also skip Terminal: open the app, click **Done** on the warning, then go to
   **System Settings › Privacy & Security**, scroll down and click **Open Anyway**.
3. Open **ClipStack** from Applications. A clipboard icon appears in the menu bar.
4. **Grant Accessibility access** when macOS asks. ClipStack needs it to press ⌘V for you
   when you hit Return.
   - Go to **System Settings › Privacy & Security › Accessibility** and turn on **ClipStack**.
   - If you missed the prompt, use the menu bar icon › **Grant Accessibility Access…**
   - Without it, Return still puts the item on your clipboard. You'd then press ⌘V yourself.
5. That's it. ClipStack registers itself to **open at login** the first time it runs from
   `/Applications`. You can toggle this in menu bar icon › **Settings…**, or in
   **System Settings › General › Login Items**.

## Install from source (one command)

Building ClipStack on your own Mac avoids the "unidentified developer" warning entirely.
Open Terminal in this folder and run:

```bash
./install.sh
```

The script checks your Mac, builds the app, installs it in Applications, and starts it.
It needs Apple's free Command Line Tools; if they're missing, it opens their installer and
asks you to run it again afterwards. Xcode isn't needed. Afterwards, grant the Accessibility
permission when macOS asks (step 4 above). Run `./install.sh` again to update, and
`./uninstall.sh` to remove everything.

**Using GitHub Copilot, Claude Code or another AI assistant?** Open this folder in your editor
and ask:

> Install ClipStack on my Mac by following AGENTS.md.

The assistant reads `AGENTS.md` (Copilot also reads `.github/copilot-instructions.md`), runs the
installer, and tells you about the one permission you have to grant yourself.

To only build without installing, run `./build.sh`. It creates `build/ClipStack.app` and the
shareable `dist/ClipStack-<version>.zip`.

## Sharing

- **Ready-made app:** run `./build.sh` and send `dist/ClipStack-1.0.0.zip`. It already contains
  a plain-text install guide.
- **Source (best for people outside your company or using an AI assistant):** run
  `./scripts/package_source.sh` and send `dist/ClipStack-source-1.0.0.zip`. They unzip it and
  run `./install.sh`, or ask their AI assistant to do it.

## Updating

Build or download the new version, quit ClipStack from the menu bar, replace the app in
`/Applications`, and open it again.

Each new build has a new ad-hoc signature, so macOS may forget the Accessibility permission. If
pasting stops working after an update, open **System Settings › Privacy & Security ›
Accessibility**, remove ClipStack with the **–** button, and turn it on again.

## Uninstall

1. Quit ClipStack from the menu bar icon.
2. Turn off **Open ClipStack at login** in Settings first, or remove it in **System Settings › General › Login Items**.
3. Delete `/Applications/ClipStack.app` and the history folder:

   ```bash
   rm -rf ~/Library/Application\ Support/ClipStack
   ```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| "ClipStack can't be opened" / "unidentified developer" | Run the `xattr` command from step 2 of the install. |
| Return closes the panel but nothing is pasted | Accessibility permission is missing or stale. See **Updating** above. |
| "ClipStack would like to control this computer" keeps appearing although it's already enabled | The switch belongs to an older build. In **Accessibility**, select ClipStack, click **–** to remove it, then click **+** and add `/Applications/ClipStack.app` again. Quit and reopen ClipStack. |
| The shortcut does nothing | Another app is using it. ClipStack shows an alert at launch when this happens. Pick a different shortcut in **Settings…** |
| Finder's "Move item here" (⌥⌘V) stopped working | ClipStack takes over that shortcut. Use Edit › Move Item Here in Finder, or give ClipStack a different shortcut in Settings. |
| It didn't start after a reboot | Check **System Settings › General › Login Items** and make sure ClipStack is listed and allowed. |

## Limitations

- Only plain text is kept. Images, files, and rich text formatting aren't stored.
- Pasting uses the ⌘V key position. That's fine for QWERTY and AZERTY, but it may not work on
  unusual layouts like Dvorak – QWERTY ⌘.

## Project layout

```
Sources/ClipStack/
  main.swift            app entry point (menu-bar-only app)
  AppDelegate.swift     menu bar item, hot key, startup
  ClipboardStore.swift  watches the pasteboard, keeps the last 10 copies, saves to disk
  HotKey.swift          global ⌥⌘V shortcut (Carbon hot-key API)
  PanelController.swift floating panel and keyboard handling
  ClipboardView.swift   SwiftUI interface
  Paster.swift          sends ⌘V to the previous app
  LoginItem.swift       open-at-login (ServiceManagement)
  Settings.swift        saved preferences: shortcut, history retention
  SettingsView.swift    Settings window and shortcut recorder
scripts/make_icon.swift renders the app icon
build.sh                build, sign (ad-hoc), zip, install
```
