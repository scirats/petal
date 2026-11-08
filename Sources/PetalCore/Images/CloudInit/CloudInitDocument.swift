import Foundation

struct CloudInitDocument {
    let account: GuestAccount
    let hostname: String
    let desktop: Bool

    func render() -> String {
        var packages = ["spice-vdagent"]
        if desktop {
            packages.append("ubuntu-desktop-minimal")
        }

        let sharedTag = DirectoryShareTag.shared
        let rosettaTag = DirectoryShareTag.rosetta
        let sharedMount = "/mnt/\(sharedTag)"
        let rosettaMount = "/mnt/\(rosettaTag)"

        var lines = [
            "#cloud-config",
            "hostname: \(YAMLString.quote(hostname))",
            "users:",
            "  - name: \(YAMLString.quote(account.username))",
            "    gecos: \(YAMLString.quote(account.fullName))",
            "    groups: [sudo]",
            "    shell: /bin/bash",
            "    sudo: \"ALL=(ALL) ALL\"",
            "    lock_passwd: false",
            "    plain_text_passwd: \(YAMLString.quote(account.password))",
            "ssh_pwauth: true",
            "package_update: true",
            "packages: [\(packages.map(YAMLString.quote).joined(separator: ", "))]",
            "runcmd:",
            "  - [sh, -c, \"mkdir -p \(sharedMount) \(rosettaMount)\"]",
            "  - [sh, -c, \"grep -q ' \(sharedMount) ' /etc/fstab || "
                + "echo '\(sharedTag) \(sharedMount) virtiofs defaults,nofail 0 0' >> /etc/fstab\"]",
            "  - [sh, -c, \"grep -q ' \(rosettaMount) ' /etc/fstab || "
                + "echo '\(rosettaTag) \(rosettaMount) virtiofs ro,nofail 0 0' >> /etc/fstab\"]",
            "  - [sh, -c, \"mount -a || true\"]",
        ]

        if desktop {
            lines += [
                "  - [systemctl, set-default, graphical.target]",
                "power_state:",
                "  mode: reboot",
                "  message: Desktop installed, restarting",
                "  condition: true",
            ]
        }

        return lines.joined(separator: "\n") + "\n"
    }
}

private enum YAMLString {
    static func quote(_ text: String) -> String {
        var escaped = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\":
                escaped += #"\\"#
            case "\"":
                escaped += #"\""#
            case "\n":
                escaped += #"\n"#
            case "\r":
                escaped += #"\r"#
            case "\t":
                escaped += #"\t"#
            default:
                if scalar.value < 0x20 {
                    escaped += String(format: "\\x%02X", scalar.value)
                } else {
                    escaped.unicodeScalars.append(scalar)
                }
            }
        }
        return "\"\(escaped)\""
    }
}
