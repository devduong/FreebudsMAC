// OFBCore/Config/L10n.swift
// Modular Multilingual Localization Engine

import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case vietnamese = "vi"
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case russian = "ru"
    case french = "fr"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            let resolved = AppLanguage.resolveSystemLanguage()
            return "\(L10n.tr("lang_system")) (\(resolved.nativeName))"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        case .chineseSimplified: return "简体中文 (Simplified Chinese)"
        case .chineseTraditional: return "繁體中文 (Traditional Chinese)"
        case .russian: return "Русский"
        case .french: return "Français"
        }
    }

    public var nativeName: String {
        switch self {
        case .system: return "System"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .russian: return "Русский"
        case .french: return "Français"
        }
    }

    public static func resolveSystemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.language.languageCode?.identifier ?? "en"
        let code = preferred.lowercased()

        if code.hasPrefix("vi") { return .vietnamese }
        if code.hasPrefix("ru") { return .russian }
        if code.hasPrefix("fr") { return .french }
        if code.contains("hant") || code.contains("tw") || code.contains("hk") || code.contains("mo") {
            return .chineseTraditional
        }
        if code.hasPrefix("zh") || code.contains("hans") || code.contains("cn") || code.contains("sg") {
            return .chineseSimplified
        }
        return .english // Default fallback to English if system language is unsupported
    }
}

public enum L10n {
    public static var currentLanguage: AppLanguage = .system {
        didSet {
            effectiveLanguage = (currentLanguage == .system) ? AppLanguage.resolveSystemLanguage() : currentLanguage
        }
    }
    public static var effectiveLanguage: AppLanguage = AppLanguage.resolveSystemLanguage()

    /// Retrieve localized string by key with automatic fallback to English
    public static func tr(_ key: String) -> String {
        switch effectiveLanguage {
        case .vietnamese:
            return L10n_VI.dict[key] ?? L10n_EN.dict[key] ?? key
        case .chineseSimplified:
            return L10n_ZH_Hans.dict[key] ?? L10n_EN.dict[key] ?? key
        case .chineseTraditional:
            return L10n_ZH_Hant.dict[key] ?? L10n_EN.dict[key] ?? key
        case .russian:
            return L10n_RU.dict[key] ?? L10n_EN.dict[key] ?? key
        case .french:
            return L10n_FR.dict[key] ?? L10n_EN.dict[key] ?? key
        case .english, .system:
            return L10n_EN.dict[key] ?? key
        }
    }

    /// Retrieve localized formatted string with arguments
    public static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, arguments: args)
    }
}
