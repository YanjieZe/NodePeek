# Contributing

1. Use an Apple Silicon Mac with macOS 13+ and Apple Command Line Tools.
2. Run `./test.sh` before and after relevant changes. Tests use synthetic config files and isolated preferences; they never SSH to real machines.
3. Build with `./build.sh`. Verify affected interactions in the app.
4. Add translations to `Sources/Localization.swift` for new UI copy. `L()` follows macOS language preferences. `NODEPEEK_LANGUAGE=en` or `zh-Hans` is a test/demo override, not a system-wide setting.
5. Use `./demo.sh` to render synthetic screenshots. Do not upload screenshots of private machines.
6. Keep pull requests focused and describe validation and limitations.

See [release instructions](docs/RELEASING.md) for packaging. The app currently targets Linux system metrics and NVIDIA GPUs, with no third-party runtime dependencies.

The bundle identifier remains `local.remotemeter.app` to preserve preferences when upgrading from RemoteMeter. Keep this identifier stable.

Installation changes must pass `./Tests/test_install.sh`, which installs into a temporary directory, checks overwrite refusal, upgrades and restores the backup without launching the app or touching SSH.
