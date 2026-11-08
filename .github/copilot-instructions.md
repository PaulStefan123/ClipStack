This repository is ClipStack, a macOS clipboard manager written in Swift.

If the user wants it installed, follow the steps in `AGENTS.md` at the repository root. In short:

1. Run `chmod +x install.sh build.sh uninstall.sh && ./install.sh` from the repository root.
   Use a long timeout, because the first build takes 1–2 minutes. Don't use sudo.
2. If the script says the Command Line Tools are missing, tell the user to click Install in the
   macOS dialog, wait for it to finish, then run `./install.sh` again.
3. Tell the user to grant the Accessibility permission themselves. When macOS asks, click
   "Open System Settings", turn on ClipStack, then quit and reopen ClipStack. Scripts can't do
   this step.
4. Usage: ⌥⌘V opens the list, ↑/↓ choose an item, Return pastes it, and Settings is in the menu bar icon.

Uninstall with `./uninstall.sh`.
