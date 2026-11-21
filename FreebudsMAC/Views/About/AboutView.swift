// OpenFreebuds/Views/About/AboutView.swift

import SwiftUI
import OFBPlatform
import OFBCore

private enum AboutSubTab: String, CaseIterable, Identifiable {
    case info
    case supportedDevices

    var id: String { rawValue }
}

struct AboutView: View {
    @State private var subTab: AboutSubTab = .info
    @ObservedObject private var updateChecker = UpdateChecker.shared

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Header Bar (About | Supported Devices)
            HStack {
                Picker("", selection: $subTab) {
                    Text(L10n.tr("tab_about")).tag(AboutSubTab.info)
                    Text(L10n.tr("tab_supported_devices")).tag(AboutSubTab.supportedDevices)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 340)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            switch subTab {
            case .info:
                aboutInfoContent
            case .supportedDevices:
                SupportedDevicesView()
            }
        }
    }

    private var aboutInfoContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "headphones")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 68, height: 68)
                    .foregroundColor(.accentColor)

                VStack(spacing: 8) {
                    Text(AppVersion.appName)
                        .font(.title)
                        .bold()

                    Text(AppVersion.displayVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        Task {
                            await updateChecker.checkForUpdates(isManual: true)
                        }
                    }) {
                        HStack(spacing: 6) {
                            if updateChecker.isChecking {
                                ProgressView()
                                    .controlSize(.small)
                                Text(L10n.tr("checking_updates"))
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(L10n.tr("check_for_updates_btn"))
                            }
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(updateChecker.isChecking)
                    .padding(.top, 4)
                }

                Text(L10n.tr("about_app_description"))
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .padding(.horizontal)

                // Unlisted Devices & Generic Driver Note Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text(L10n.tr("about_unlisted_devices_title"))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text(L10n.tr("about_unlisted_devices_hint"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

                Divider()

                HStack(spacing: 20) {
                    Link(L10n.tr("github_repo"), destination: URL(string: "https://github.com/devduong/FreebudsMAC")!)
                    Link(L10n.tr("license"), destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
                }
            }
            .padding(24)
        }
    }
}
