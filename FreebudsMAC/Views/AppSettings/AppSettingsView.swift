// OpenFreebuds/Views/AppSettings/AppSettingsView.swift

import SwiftUI
import OFBCore

struct AppSettingsView: View {
    @ObservedObject var config: AppConfig

    var body: some View {
        Form {
            Section(L10n.tr("language")) {
                Picker(L10n.tr("language"), selection: $config.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(L10n.tr("tray_options")) {
                Toggle(L10n.tr("show_battery_in_tray"), isOn: $config.showBatteryInTray)

                if config.showBatteryInTray {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(L10n.tr("show_left_battery_in_tray"), isOn: $config.showLeftBatteryInTray)
                        Toggle(L10n.tr("show_right_battery_in_tray"), isOn: $config.showRightBatteryInTray)
                        Toggle(L10n.tr("show_case_battery_in_tray"), isOn: $config.showCaseBatteryInTray)
                    }
                    .padding(.leading, 16)
                }

                Toggle(L10n.tr("show_equalizer_in_tray"), isOn: $config.trayShowEqualizer)
                Toggle(L10n.tr("show_dual_connect_in_tray"), isOn: $config.trayShowDualConnect)
                Toggle(L10n.tr("run_in_background"), isOn: $config.runInBackground)
            }

            Section(L10n.tr("notifications_section")) {
                Toggle(L10n.tr("notify_low_battery"), isOn: $config.notifyLowBattery)
                Text(L10n.tr("notify_low_battery_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
