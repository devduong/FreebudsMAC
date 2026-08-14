// OFBPlatform/LaunchAgent.swift

import Foundation

public enum LaunchAgentManager {
    public static let label = "pw.mmk.FreebudsMAC"

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    /// Check if run at boot (LaunchAgent plist exists)
    public static var isRunAtBoot: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    /// Enable or disable autostart at boot via LaunchAgent
    public static func setRunAtBoot(_ enable: Bool) throws {
        let fileManager = FileManager.default
        let plistURL = launchAgentURL

        if enable {
            let directory = plistURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments.first ?? ""

            let plistDict: [String: Any] = [
                "Label": label,
                "ProgramArguments": [executablePath, "--autostart"],
                "RunAtLoad": true,
                "KeepAlive": false,
                "ProcessType": "Interactive"
            ]

            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plistDict,
                format: .xml,
                options: 0
            )
            try plistData.write(to: plistURL)

            runLaunchControl(["load", "-w", plistURL.path])
        } else {
            if fileManager.fileExists(atPath: plistURL.path) {
                runLaunchControl(["unload", "-w", plistURL.path])
                try fileManager.removeItem(at: plistURL)
            }
        }
    }

    private static func runLaunchControl(_ args: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        try? process.run()
    }
}
