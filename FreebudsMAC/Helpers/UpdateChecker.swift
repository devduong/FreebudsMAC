// FreebudsMAC/Helpers/UpdateChecker.swift

import Foundation
import AppKit
import SwiftUI
import OFBCore

public struct RemoteVersionInfo: Sendable {
    public let version: String
    public let dmgDownloadURL: URL
    public let releasePageURL: URL
    public let releaseNotes: String?
}

@MainActor
public final class UpdateChecker: ObservableObject {
    public static let shared = UpdateChecker()

    @Published public private(set) var isChecking: Bool = false
    @Published public private(set) var isInstalling: Bool = false
    @Published public private(set) var installStatusText: String = ""
    @Published public private(set) var latestAvailableVersion: String? = nil
    @Published public private(set) var latestRemoteInfo: RemoteVersionInfo? = nil

    private var progressWindow: NSWindow?

    private let releasesAPIURL = URL(string: "https://api.github.com/repos/devduong/FreebudsMAC/releases/latest")!
    private let tagsAPIURL = URL(string: "https://api.github.com/repos/devduong/FreebudsMAC/tags")!
    private let rawAppVersionURL = URL(string: "https://raw.githubusercontent.com/devduong/FreebudsMAC/main/Sources/OFBCore/Config/AppVersion.swift")!
    private let releasesWebURL = URL(string: "https://github.com/devduong/FreebudsMAC/releases")!
    private let repoWebURL = URL(string: "https://github.com/devduong/FreebudsMAC")!

    private init() {}

    /// Standard direct DMG download URL on GitHub Releases for a given version
    private func defaultDMGURL(for version: String) -> URL {
        let dmgName = "\(AppVersion.appName)_\(AppVersion.architecture)_\(version).dmg"
        return URL(string: "https://github.com/devduong/FreebudsMAC/releases/download/v\(version)/\(dmgName)") ?? releasesWebURL
    }

    /// Check for updates from the public repository (`devduong/FreebudsMAC`).
    public func checkForUpdates(isManual: Bool = false) async {
        let config = AppConfig.shared

        // If user clicked the toolbar "New version available" badge and we already cached remoteInfo, show popup immediately
        if isManual, let cachedInfo = latestRemoteInfo, Self.isNewerVersion(cachedInfo.version, than: AppVersion.version) {
            showUpdateAvailablePopup(remoteInfo: cachedInfo, currentVersion: AppVersion.version)
            return
        }

        guard !isChecking && !isInstalling else { return }
        isChecking = true
        defer { isChecking = false }

        do {
            let remoteInfo = try await fetchLatestPublicVersion()
            let currentVersion = AppVersion.version

            if Self.isNewerVersion(remoteInfo.version, than: currentVersion) {
                self.latestAvailableVersion = remoteInfo.version
                self.latestRemoteInfo = remoteInfo

                // Only suppress automatic popup when user disabled auto-check or skipped this version;
                // the toolbar indicator badge will still display!
                if !isManual {
                    guard config.autoCheckUpdates else { return }
                    guard config.skippedUpdateVersion != remoteInfo.version else { return }
                }

                showUpdateAvailablePopup(remoteInfo: remoteInfo, currentVersion: currentVersion)
            } else {
                self.latestAvailableVersion = nil
                self.latestRemoteInfo = nil
                if isManual {
                    showUpToDatePopup(currentVersion: currentVersion)
                }
            }
        } catch {
            if isManual {
                showErrorPopup()
            }
        }
    }

    // MARK: - Fetch Version from Public GitHub Repository

    private func fetchLatestPublicVersion() async throws -> RemoteVersionInfo {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 10
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: sessionConfig)

        var bestInfo: RemoteVersionInfo? = nil

        // 1. Check GitHub Releases API (/repos/devduong/FreebudsMAC/releases/latest)
        if let releaseInfo = try? await fetchFromGitHubRelease(session: session) {
            bestInfo = releaseInfo
        }

        // 2. Check raw AppVersion.swift on public main branch
        if let rawInfo = try? await fetchFromRawAppVersion(session: session) {
            if let existing = bestInfo {
                if Self.isNewerVersion(rawInfo.version, than: existing.version) {
                    bestInfo = rawInfo
                }
            } else {
                bestInfo = rawInfo
            }
        }

        // 3. Fallback: Check GitHub Tags API (/repos/devduong/FreebudsMAC/tags)
        if bestInfo == nil, let tagInfo = try? await fetchFromGitHubTags(session: session) {
            bestInfo = tagInfo
        }

        if let result = bestInfo {
            return result
        }

        throw URLError(.cannotParseResponse)
    }

    private func fetchFromGitHubRelease(session: URLSession) async throws -> RemoteVersionInfo? {
        var req = URLRequest(url: releasesAPIURL)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("FreebudsMAC/\(AppVersion.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String else {
            return nil
        }

        let cleanVersion = Self.normalizeVersion(tagName)
        guard !cleanVersion.isEmpty else { return nil }

        var pageURL = releasesWebURL
        if let htmlUrlStr = json["html_url"] as? String, let htmlURL = URL(string: htmlUrlStr) {
            pageURL = htmlURL
        }

        var dmgURL = defaultDMGURL(for: cleanVersion)
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String,
                   name.lowercased().hasSuffix(".dmg"),
                   let dlStr = asset["browser_download_url"] as? String,
                   let dlURL = URL(string: dlStr) {
                    dmgURL = dlURL
                    break
                }
            }
        }

        let body = (json["body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return RemoteVersionInfo(
            version: cleanVersion,
            dmgDownloadURL: dmgURL,
            releasePageURL: pageURL,
            releaseNotes: body
        )
    }

    private func fetchFromRawAppVersion(session: URLSession) async throws -> RemoteVersionInfo? {
        var req = URLRequest(url: rawAppVersionURL)
        req.setValue("FreebudsMAC/\(AppVersion.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let pattern = #"static\s+let\s+version\s*=\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let range = Range(match.range(at: 1), in: content) else {
            return nil
        }

        let cleanVersion = Self.normalizeVersion(String(content[range]))
        guard !cleanVersion.isEmpty else { return nil }

        return RemoteVersionInfo(
            version: cleanVersion,
            dmgDownloadURL: defaultDMGURL(for: cleanVersion),
            releasePageURL: releasesWebURL,
            releaseNotes: nil
        )
    }

    private func fetchFromGitHubTags(session: URLSession) async throws -> RemoteVersionInfo? {
        var req = URLRequest(url: tagsAPIURL)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("FreebudsMAC/\(AppVersion.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let tags = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstTag = tags.first,
              let name = firstTag["name"] as? String else {
            return nil
        }

        let cleanVersion = Self.normalizeVersion(name)
        guard !cleanVersion.isEmpty else { return nil }
        return RemoteVersionInfo(
            version: cleanVersion,
            dmgDownloadURL: defaultDMGURL(for: cleanVersion),
            releasePageURL: releasesWebURL,
            releaseNotes: nil
        )
    }

    // MARK: - SemVer Comparison

    public static func normalizeVersion(_ raw: String) -> String {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            trimmed.removeFirst()
        }
        return trimmed
    }

    public static func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        let candParts = normalizeVersion(candidate).split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }
        let currParts = normalizeVersion(current).split(separator: ".").map { Int($0.prefix(while: { $0.isNumber })) ?? 0 }

        let count = max(candParts.count, currParts.count)
        for i in 0..<count {
            let candVal = i < candParts.count ? candParts[i] : 0
            let currVal = i < currParts.count ? currParts[i] : 0
            if candVal > currVal { return true }
            if candVal < currVal { return false }
        }
        return false
    }

    // MARK: - Native Alert Popups

    public func showUpdateAvailablePopup(remoteInfo: RemoteVersionInfo, currentVersion: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
        alert.messageText = L10n.tr("update_available_title", remoteInfo.version)

        var infoText = L10n.tr("update_available_body", remoteInfo.version, currentVersion)
        if let notes = remoteInfo.releaseNotes, !notes.isEmpty {
            let maxNotes = notes.count > 350 ? String(notes.prefix(350)) + "…" : notes
            infoText += "\n\n\(L10n.tr("update_release_notes"))\n\(maxNotes)"
        }
        alert.informativeText = infoText

        // 4 Action Buttons:
        // 1. Update & Relaunch (Auto download, replace current app & relaunch)
        alert.addButton(withTitle: L10n.tr("update_btn_download"))
        // 2. Remind Me Later
        alert.addButton(withTitle: L10n.tr("update_btn_later"))
        // 3. Skip This Version
        alert.addButton(withTitle: L10n.tr("update_btn_skip_version"))
        // 4. Never Remind Again
        alert.addButton(withTitle: L10n.tr("update_btn_never_remind"))

        let response = alert.runModal()
        let config = AppConfig.shared

        switch response {
        case .alertFirstButtonReturn:
            Task { @MainActor in
                await downloadAndInstallInPlace(remoteInfo: remoteInfo)
            }
        case .alertSecondButtonReturn:
            break
        case .alertThirdButtonReturn:
            config.skippedUpdateVersion = remoteInfo.version
        default:
            config.autoCheckUpdates = false
        }
    }

    // MARK: - Auto Download, In-Place Overwrite & Relaunch

    public func downloadAndInstallInPlace(remoteInfo: RemoteVersionInfo) async {
        guard !isInstalling else { return }
        isInstalling = true
        installStatusText = L10n.tr("update_downloading_status")
        showInstallProgressWindow(version: remoteInfo.version)

        let uuid = UUID().uuidString
        let fm = FileManager.default
        let tempBase = fm.temporaryDirectory.appendingPathComponent("FreebudsMAC_Updater_\(uuid)")
        let dmgFile = tempBase.appendingPathComponent("update.dmg")
        let mountPoint = tempBase.appendingPathComponent("mnt")
        let stagedApp = tempBase.appendingPathComponent("\(AppVersion.appName).app")

        do {
            try fm.createDirectory(at: tempBase, withIntermediateDirectories: true)
            try fm.createDirectory(at: mountPoint, withIntermediateDirectories: true)

            // 1. Download DMG from GitHub Release
            var req = URLRequest(url: remoteInfo.dmgDownloadURL)
            req.setValue("FreebudsMAC/\(AppVersion.version)", forHTTPHeaderField: "User-Agent")

            let (tempLocalURL, response) = try await URLSession.shared.download(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "UpdateChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"])
            }

            if fm.fileExists(atPath: dmgFile.path) {
                try fm.removeItem(at: dmgFile)
            }
            try fm.moveItem(at: tempLocalURL, to: dmgFile)

            // 2. Mount DMG and extract .app bundle
            installStatusText = L10n.tr("update_extracting_status")

            try await runProcess("/usr/bin/hdiutil", arguments: [
                "attach", "-nobrowse", "-readonly", "-noverify", "-noautoopen",
                "-mountpoint", mountPoint.path,
                dmgFile.path
            ])

            let mountedApp = mountPoint.appendingPathComponent("\(AppVersion.appName).app")
            guard fm.fileExists(atPath: mountedApp.path) else {
                _ = try? await runProcess("/usr/bin/hdiutil", arguments: ["detach", mountPoint.path, "-force"])
                throw NSError(domain: "UpdateChecker", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(AppVersion.appName).app not found inside DMG"])
            }

            try await runProcess("/usr/bin/ditto", arguments: [mountedApp.path, stagedApp.path])
            _ = try? await runProcess("/usr/bin/xattr", arguments: ["-cr", stagedApp.path])
            _ = try? await runProcess("/usr/bin/hdiutil", arguments: ["detach", mountPoint.path, "-force"])

            // 3. Determine current running .app path to overwrite
            installStatusText = L10n.tr("update_relaunching_status")
            let bundlePath = Bundle.main.bundlePath
            let targetAppPath: String
            if bundlePath.hasSuffix(".app") && !bundlePath.hasPrefix("/Volumes/") {
                targetAppPath = bundlePath
            } else {
                targetAppPath = "/Applications/\(AppVersion.appName).app"
            }

            // 4. Spawn detached updater script that waits for current PID to exit, replaces .app, and relaunches
            let pid = ProcessInfo.processInfo.processIdentifier
            let script = """
            (
                for i in $(seq 1 30); do
                    if ! kill -0 \(pid) 2>/dev/null; then
                        break
                    fi
                    sleep 0.2
                done
                rm -rf "\(targetAppPath)" 2>/dev/null
                /usr/bin/ditto "\(stagedApp.path)" "\(targetAppPath)"
                /usr/bin/xattr -cr "\(targetAppPath)" 2>/dev/null
                rm -rf "\(tempBase.path)" 2>/dev/null
                /usr/bin/open "\(targetAppPath)"
            ) >/dev/null 2>&1 &
            """

            let updaterTask = Process()
            updaterTask.executableURL = URL(fileURLWithPath: "/bin/sh")
            updaterTask.arguments = ["-c", script]
            try updaterTask.run()

            try? await Task.sleep(nanoseconds: 300_000_000)
            closeInstallProgressWindow()
            NSApplication.shared.terminate(nil)
            exit(0)
        } catch {
            closeInstallProgressWindow()
            isInstalling = false
            try? fm.removeItem(at: tempBase)

            let errAlert = NSAlert()
            errAlert.alertStyle = .warning
            errAlert.messageText = L10n.tr("update_error_title")
            errAlert.informativeText = L10n.tr("update_install_failed_body", error.localizedDescription)
            errAlert.addButton(withTitle: "OK")
            errAlert.runModal()

            NSWorkspace.shared.open(remoteInfo.releasePageURL)
        }
    }

    @discardableResult
    private func runProcess(_ launchPath: String, arguments: [String]) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: launchPath)
                proc.arguments = arguments
                proc.standardOutput = Pipe()
                proc.standardError = Pipe()
                do {
                    try proc.run()
                    proc.waitUntilExit()
                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: proc.terminationStatus)
                    } else {
                        continuation.resume(throwing: NSError(
                            domain: "UpdateCheckerProcess",
                            code: Int(proc.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: "\(URL(fileURLWithPath: launchPath).lastPathComponent) exited with code \(proc.terminationStatus)"]
                        ))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Progress Window UI

    private func showInstallProgressWindow(version: String) {
        closeInstallProgressWindow()

        let view = UpdateProgressView(checker: self, version: version)
        let hc = NSHostingController(rootView: view)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 130),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        win.title = AppVersion.appName
        win.contentViewController = hc
        win.isReleasedWhenClosed = false
        win.level = .floating
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.progressWindow = win
    }

    private func closeInstallProgressWindow() {
        progressWindow?.close()
        progressWindow = nil
    }

    private func showUpToDatePopup(currentVersion: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "checkmark.seal.fill", accessibilityDescription: nil)
        alert.messageText = L10n.tr("update_up_to_date_title")
        alert.informativeText = L10n.tr("update_up_to_date_body", currentVersion)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showErrorPopup() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.tr("update_error_title")
        alert.informativeText = L10n.tr("update_error_body")
        alert.addButton(withTitle: L10n.tr("github_repo"))
        alert.addButton(withTitle: L10n.tr("cancel"))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(repoWebURL)
        }
    }
}

private struct UpdateProgressView: View {
    @ObservedObject var checker: UpdateChecker
    let version: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr("update_installing_title", version))
                        .font(.headline)
                    Text(checker.installStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            ProgressView()
                .progressViewStyle(.linear)
        }
        .padding(20)
        .frame(width: 380, height: 120)
    }
}
