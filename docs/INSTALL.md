# Installation

## Option A: build locally

Use an Apple Silicon Mac on macOS 13+. Install Apple Command Line Tools, clone the repository and run:

```bash
./build.sh
open NodePeek.app
```

The app can then be moved to Applications. Local compilation does not require a paid Apple Developer membership.

## Option B: download the preview ZIP

1. Download the ZIP and corresponding `.sha256` from the repository's release or CI artifacts. While the repo is private, access is limited to invited members; release drafts are visible to repository users with appropriate permissions.
2. Verify the checksum in the download folder, replacing VERSION with the actual version:

   ```bash
   shasum -a 256 -c NodePeek-VERSION-macOS-arm64.zip.sha256
   ```

3. Extract the ZIP and move NodePeek.app into Applications.
4. Launch it. These builds are **ad-hoc signed, not Developer ID signed and not notarized**. If macOS blocks launch and you trust the source, follow [Apple's per-app Open Anyway instructions](https://support.apple.com/en-us/102445) in System Settings → Privacy & Security. This exception is your choice; the app does not make it for you. If the exception is unavailable, build from source instead.

Do not disable Gatekeeper globally, remove unrelated quarantine attributes, or run the app as root. A checksum verifies consistency with the uploaded archive, not the trustworthiness of its author.

## SSH setup

First establish a successful interactive SSH connection in Terminal and verify the host key. Use a key or an unlocked SSH agent; the app does not prompt for passwords. Remote Python 3 must be discoverable in the non-interactive SSH PATH. `nvidia-smi` is optional for CPU-only hosts.

## Window and menu bar

Closing the main window hides it; the app and SSH sessions continue running. Click the Dock icon to restore it. Use Quit or ⌘Q to exit. The menu bar icon and optional metrics text can be toggled in the main window. Put the app in its final Applications location before enabling Launch at login.

## Language

The app follows macOS language preferences and supports English and Simplified Chinese. Other languages fall back to English. Quit and reopen after changing the app's language preferences in macOS.

## 中文简要说明

下载包目前未经过 Apple 公证。确认来源可信后，可按 Apple 官方说明在“系统设置 → 隐私与安全性”中选择“仍要打开”；也可以直接从源码构建。不要全局关闭系统安全保护。首次使用先在终端验证 SSH，再在应用中选择机器。
