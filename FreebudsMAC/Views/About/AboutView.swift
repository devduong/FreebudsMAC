// OpenFreebuds/Views/About/AboutView.swift

import SwiftUI
import OFBPlatform
import OFBCore

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "headphones")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 72)
                    .foregroundColor(.accentColor)

                VStack(spacing: 4) {
                    Text(AppVersion.appName)
                        .font(.title)
                        .bold()

                    Text(AppVersion.displayVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
            .padding(20)
        }
    }
}

