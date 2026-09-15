# Release process

## Local validation

```bash
./test.sh
./Tests/test_install.sh
./package.sh
```

`dist/` contains an Apple Silicon ZIP and SHA-256 checksum. The bundle is ad-hoc signed and verified locally, without a Developer ID identity or notarization. Source builds need Command Line Tools; consumers of the ZIP do not need Xcode.

## Automation

- Main-branch pushes and pull requests run offline tests in both languages, build, package and upload a CI artifact.
- Version tags create a **draft prerelease**, including the ZIP and checksum. Nothing is published automatically.
- Hosted macOS jobs use the repository owner's GitHub Actions allocation. No paid larger-runner configuration is required.
- Actions are pinned to commit SHAs. Release permissions are limited to contents write.

To prepare a version, edit `VERSION`, `CFBundleVersion` in `build.sh`, and `docs/RELEASE_NOTES.md`; run tests and packaging, commit, then tag:

```bash
VERSION=$(tr -d '\n' < VERSION)
git tag "v$VERSION"
git push origin "v$VERSION"
```

Review the workflow result and draft release. The repository is public. Drafts stay unpublished until deliberately published; publishing a release does not change repository visibility.

## Future Developer ID distribution

A paid Apple Developer membership, Developer ID certificate and notarization credentials will be needed for a notarized distribution. Keep these in GitHub secrets or a local keychain, never in the repo. The current workflow deliberately requires none of them.
