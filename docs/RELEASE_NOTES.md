## NodePeek 0.7.1 — private preview

Your remote machines, at a glance.

- Renamed RemoteMeter to NodePeek; existing host selections and ordering are preserved.
- Native macOS desktop and compact menu bar monitoring over SSH.
- English and Simplified Chinese UI, following system language preferences.
- First-run host selection, multi-host overview, per-GPU details and connection diagnostics.
- Drag to reorder hosts, persistent preferences, reconnect and sleep recovery.
- Closing the main window hides it while monitoring continues.

### Requirements

Apple Silicon Mac, macOS 13+. Remote Linux with Python 3; NVIDIA metrics require nvidia-smi. SSH uses existing keys/agent and verified host keys.

### Installation and signing

Download the macOS arm64 ZIP and its SHA-256 file. The app is ad-hoc signed, **not Developer ID signed or notarized**. macOS may block the initial launch. Prefer building from source if you do not wish to override that warning; otherwise follow the documented Apple per-app approval flow only after verifying the source. Do not disable Gatekeeper globally.

This release remains a draft in a private repository. It is not a public launch.
