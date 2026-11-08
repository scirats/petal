# Notes for coding agents

- Build with `swift build`; test with `swift test`. Build the app bundle with
  `./scripts/build-app.sh`.
- Booting a VM needs the virtualization entitlement. Use `build/petalctl` from
  `./scripts/build-app.sh`, not the unsigned debug binary.
- Engine code lives in `Sources/PetalCore` and must not import SwiftUI. The app
  (`Sources/Petal`) and the CLI (`Sources/petalctl`) are thin layers on top of it.
- The app UI uses Luminare. Prefer its sections, rows, buttons, toggles, sliders,
  pickers, and text fields over raw SwiftUI controls when an equivalent exists.
- UI spacing, sizes, and Luminare settings live in `Sources/Petal/Views/Design`.
  Use the tokens and the `PetalPane`/`PetalSheet`/`PetalRoot` scaffolds instead of
  hardcoded paddings or per-view overrides.
- CLI commands belong in `Sources/PetalCLI`; `Sources/petalctl` only starts the CLI.
- Add engine tests in `Tests/PetalCoreTests` and parser or command tests in
  `Tests/PetalCLITests`.
- Do not write comments in code. Names and structure carry the meaning.
- Keep files small and single-purpose. Prefer a new focused type over a growing switch or
  view.
- Do not commit anything from `build/` or `.build/`.
- Guest account passwords end up in generated setup media; never log them.
