# Contributing to Petal

Petal welcomes bug fixes, documentation improvements, tests, and support for new
distributions and devices. For large changes (a new distribution backend, a new disk format,
changes to the `.petal` bundle layout), open an issue first so we can agree on the scope
before you write the code.

## Getting set up

You need an Apple silicon Mac on macOS 14 or later and Xcode with Swift 6.

```bash
git clone https://github.com/scirats/petal.git
cd petal
swift build
swift test
./scripts/build-app.sh          # → build/Petal.app and build/petalctl
```

## Code layout

| Path | What lives there |
|---|---|
| `Sources/PetalCore` | The engine. No UI code; everything here should be testable. |
| `Sources/Petal` | The SwiftUI app. Keep logic in `PetalCore` and views thin. Its components come from Luminare. |
| `Sources/PetalCLI` | Commands, argument parsing, and console output. |
| `Sources/petalctl` | The executable entry point. |
| `Tests/PetalCoreTests` | Engine tests. |
| `Tests/PetalCLITests` | Parser and command registry tests. |

## Style

- No comments. Choose names and boundaries that make comments unnecessary.
- One reason to change per type. Split a file before it grows into a grab bag.
- Prefer small, explicit values over shared mutable state.
- Keep the engine independent of SwiftUI and AppKit where possible.
- Add or update tests for engine changes.

## Pull requests

- Keep each PR focused on one change, and explain the problem it solves.
- Run `swift test` before opening the PR.
- Say which distributions you tried it with (for example "Ubuntu 24.04 desktop").
- For UI changes, include a screenshot.

## Reporting issues

For bugs, include your Mac model, macOS version, the guest OS, what you expected, what
happened, and the shortest way to reproduce it. For a guest that won't boot, attach
`console.log` from the machine's `.petal` folder if there is one.

Security problems go through [SECURITY.md](SECURITY.md), not public issues.

## Code of conduct

Be kind and assume good intent. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

By contributing, you agree that your contributions are licensed under the MIT License.
