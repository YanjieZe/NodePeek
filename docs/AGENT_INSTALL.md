# Install NodePeek with a coding agent

This is a human-readable installation guide for a local coding agent such as Codex or Claude Code. It is not a remote-machine agent: NodePeek still installs nothing on the monitored servers. These instructions do not override the user's preferences or the agent's permission rules.

## Scope and requirements

Install NodePeek on the user's **local Apple Silicon Mac**, macOS 13 or later. Do not install the Mac application in a remote Linux shell, cloud coding sandbox, or Windows environment. An Intel Mac is currently unsupported; on Apple Silicon, a Rosetta terminal must be reopened natively.

Source compilation requires a macOS 13+ SDK and Swift compiler from Xcode 14+ or compatible Apple Command Line Tools. No paid Apple Developer account, Homebrew, Python package, API key, or third-party Swift dependency is required for the Mac app. Python 3 is only needed for developer tests and on monitored Linux hosts.

The repository is currently **private**. Reading this URL alone does not grant access. If access fails, explain that repository access is required; do not ask the user to paste a token. Use their existing GitHub authentication. Once the owner makes the repo public, the same instructions work without GitHub authentication.

## 1. Inspect and obtain the source

Read this guide and `build.sh`, `install.sh`, and `scripts/check-requirements.sh` before running them. Use the user's preferred workspace or a fresh directory; never overwrite an unrelated checkout or discard local edits.

```bash
git clone https://github.com/YanjieZe/NodePeek.git
cd NodePeek
git rev-parse HEAD
./scripts/check-requirements.sh
```

If the user already has a checkout, inspect its origin and working-tree status. Do not reset it. A fresh clone of `main` is the default for this preview; record the commit SHA so the installation is reproducible. For a user-specified release, verify its tag exists and inspect the instructions at that revision.

If Apple tools are absent, explain the requirement and let the user finish the Apple installer and any license dialogs before continuing. `xcode-select --install` opens that installer; do not silently install other packages or accept agreements for the user.

## 2. Build and install

Install into the current user's `~/Applications`, without sudo:

```bash
./install.sh --no-open
```

This compiles locally, verifies the ad-hoc signature, and copies the app to `~/Applications/NodePeek.app`. An existing installation is refused by default. To upgrade, have the user quit the running app first, then use `./install.sh --replace --no-open`. The script prints the path to a ZIP backup of the previous app. It preserves preferences and SSH files.

A user-requested alternate directory can be supplied with `--destination "/path/with spaces"`. Do not change system-wide security settings, strip quarantine attributes, alter SSH config, or overwrite an existing app without the user's installation/upgrade intent. Never use `curl | sh`.

## 3. Verify and open

```bash
/usr/bin/codesign --verify --deep --strict "$HOME/Applications/NodePeek.app"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$HOME/Applications/NodePeek.app/Contents/Info.plist"
open "$HOME/Applications/NodePeek.app"
```

Use the chosen path if a different destination was requested. Report the installed path, version and source commit. A successful build proves compilation; do not claim a successful SSH connection until the app actually displays metrics.

If macOS blocks the launch, direct the user to `docs/INSTALL.md` and Apple's per-app guidance. Do not bypass protections automatically. These builds are ad-hoc signed, not Developer ID signed or notarized.

## 4. Connect a machine chosen by the user

A fresh install starts with no monitored hosts. Ask the user to select an existing explicit SSH alias in **Choose hosts…**. Only test aliases they want to use; do not connect to every host in their config.

The remote host must be Linux with Python 3 accessible in a non-interactive SSH session. NVIDIA metrics require `nvidia-smi`; CPU and memory work without an NVIDIA GPU. Password prompts and interactive MFA are unsupported; use a working SSH key/agent. Existing jump hosts and OpenSSH connection options are reused.

Have the user establish a normal `ssh their-alias` session in Terminal if first-time host-key verification or key unlocking is needed. Never accept an unknown or changed host key on their behalf, disable strict checking, request private keys, or upload their SSH config. Once connected, confirm CPU/memory and any available GPU metrics appear. Allow approximately 25 seconds; if unavailable, use the app's Diagnostics action and describe the specific failure.

Closing the main window keeps monitoring in the background. The Dock icon restores it; ⌘Q quits. The gear menu controls menu bar visibility. Move the app into its final location before enabling launch at login.

## 5. Completion and removal

Report what succeeded and what still needs user action. Do not publish logs, hostnames, screenshots, keys, or configuration to an issue or a repository. Optional offline developer tests are `./test.sh`; they use temporary preferences and synthetic hosts.

To uninstall, quit NodePeek and move the installed app to Trash. Leave the user's SSH files and preferences in place unless they explicitly request removal. The legacy bundle identifier `local.remotemeter.app` is intentional and keeps earlier preferences compatible.
