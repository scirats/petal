<div align="center">

<img src="docs/assets/petal-icon.png" alt="Petal icon" width="128">

# Petal

### Free, open-source Linux virtual machines for Apple silicon Macs.

**Run Linux on your Mac in one click. No ISO hunting, no license fees.**

[![CI](https://github.com/scirats/petal/actions/workflows/ci.yml/badge.svg)](https://github.com/scirats/petal/actions/workflows/ci.yml)
[![MIT license](https://img.shields.io/badge/license-MIT-f4c430?style=flat-square)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple&logoColor=white)](#requirements)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white)](Package.swift)

[Quick start](#quick-start) · [Features](#features) · [How Petal works](#how-petal-works) · [Command line](#command-line) · [Project layout](#project-layout)

</div>

## Quick start

### Requirements

- Apple silicon Mac (M1 or newer) on macOS 14 Sonoma or later
- Xcode with Swift 6 to build from source

### Build and run

```bash
git clone https://github.com/scirats/petal.git
cd petal
./scripts/build-app.sh          # → build/Petal.app and build/petalctl
open build/Petal.app
```

Click **+**, pick a distribution, and click **Create**. Progress shows in the sidebar. Ubuntu and Debian boot straight into a ready system with the account you
enter; Fedora and Alpine start their installer when the download is done.

Binaries are ad-hoc signed with the `com.apple.security.virtualization` entitlement.
Set `SIGN_IDENTITY` to sign with a Developer ID instead.

## Features

| | |
|---|---|
| **No ISO hunting** | The latest Ubuntu, Fedora, Debian and Alpine come straight from each publisher, checked against the published checksums. Images are cached for reuse. |
| **Suspend & resume** | Saves memory and device state to disk and continues exactly where you left off. |
| **Instant clones & snapshots** | APFS copy-on-write: no waiting, and no extra space until the guest writes new data. |
| **Sparse disks** | Apple Sparse Image Format (ASIF) with a raw sparse fallback; disks can grow later. |
| **Integration** | Shared folders (virtio-fs), clipboard sharing (SPICE agent), Rosetta for x86-64 Linux binaries, sound, optional microphone, NAT networking. |
| **`petalctl`** | Create, configure, clone, snapshot and run machines headless from the terminal. |
| **Safe by default** | A running machine is locked against changes by other processes, and deleting moves it to the Trash. |

## How Petal works

Petal runs Linux guests directly on Virtualization.framework, booting through UEFI.

Each machine is a `<name>.petal` folder: `machine.json`, the disk, firmware state
(`efi-variables.fd`), identity files, an optional `suspended.vzvmsave`, `snapshots/`,
`console.log` (Linux serial output), and `cloud-init.iso` for cloud images. Machines live in
`~/Library/Application Support/Petal/Machines`; downloaded images live next to them in
`Petal/Images`. Set `PETAL_HOME` to move the whole data folder.

### Inside a Linux guest

```bash
sudo mount -t virtiofs petal /mnt/petal         # shared folders
sudo mount -t virtiofs rosetta /mnt/rosetta     # Rosetta (then register it with binfmt_misc)
sudo apt install spice-vdagent                  # clipboard sharing
```

## Command line

```bash
petalctl images                                 # what Petal can download
petalctl create-linux "Ubuntu" --distro ubuntu-desktop --cpus 4 --memory 8 --disk 64
petalctl share "Ubuntu" code ~/Projects --read-only
petalctl snapshot "Ubuntu" fresh install
petalctl clone "Ubuntu" "Ubuntu Test"
petalctl run "Ubuntu Test"                      # headless; Ctrl-C suspends
petalctl help
```

Hardware and sharing changes require a stopped machine. Use
`petalctl discard-suspended <name>` before changing a suspended machine.

`build/petalctl` is signed with the virtualization entitlement. A plain `swift build`
binary can manage machines but needs that entitlement before it can boot one.

`Petal -PetalAutostart "<name>"` opens and starts a machine at launch.

## Project layout

| Path | Purpose |
|---|---|
| `Sources/PetalCore` | Engine: machine storage, VM configuration, disks, snapshots, images, running sessions |
| `Sources/Petal` | SwiftUI app |
| `Sources/PetalCLI` | Command implementations and argument parsing |
| `Sources/petalctl` | CLI executable |
| `Tests/PetalCoreTests` | Engine tests |
| `Tests/PetalCLITests` | CLI parser and registry tests |
| `scripts/` | App bundle and icon build scripts |

The engine has no SwiftUI dependency. The app and the CLI are thin layers over
`PetalCore`, and every engine change is covered by tests.

## FAQ

**Can I run x64 (Intel) Linux?**
No. Virtualization.framework runs ARM64 guests only. Linux guests can run x86-64
binaries through Rosetta.

**Is there USB passthrough?**
Not yet.

**Where is my data?**
In `~/Library/Application Support/Petal/Machines`, one `.petal` folder per machine.
Nothing leaves your Mac except the installer downloads.

## Contributing

Bug reports, fixes, docs and new distribution support are all welcome. Start with
[CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgements

Petal is a modular rewrite of [Burrow](https://github.com/DaniilPak/burrow), also MIT
licensed.

The interface is built with [Luminare](https://github.com/MrKai77/Luminare), a macOS
SwiftUI design system. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for
license details.

## License

[MIT](LICENSE)
