// OFBCore/Config/AppVersion.swift

import Foundation

/// Standard Version Configuration for FreebudsMAC.
/// Single source of truth for Application Name, Version, Build Number and Architecture.
public enum AppVersion {
    public static let appName = "FreebudsMAC"
    public static let version = "0.18.0"
    public static let buildNumber = "1"
    public static let architecture = "Universal"
    
    /// User-facing display version string
    public static var displayVersion: String {
        "Version \(version) (\(architecture) Swift + SwiftUI)"
    }
    
    /// Standard DMG filename format: <AppName>_<Architecture>_<Version>.dmg
    public static var dmgFileName: String {
        "\(appName)_\(architecture)_\(version).dmg"
    }
}
