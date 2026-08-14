// OpenFreebuds/Views/SupportedDevices/SupportedDevicesView.swift

import SwiftUI
import OFBCore

struct SupportedDeviceItem: Identifiable {
    let id = UUID()
    let name: String
    let family: String
    let driverName: String
    let features: [String]
}

struct SupportedDevicesView: View {
    @State private var searchText = ""
    @State private var selectedFamily = "all"

    private let devices: [SupportedDeviceItem] = [
        SupportedDeviceItem(name: "HUAWEI FreeBuds 5i", family: "FreeBuds i", driverName: "FreeBuds 5i Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds 4i", family: "FreeBuds i", driverName: "FreeBuds 4i Driver", features: ["ANC", "Battery", "WearDetection", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds 6i", family: "FreeBuds i", driverName: "FreeBuds 6i Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Pro", family: "FreeBuds Pro", driverName: "FreeBuds Pro Driver", features: ["ANC", "Battery", "WearDetection", "Gestures", "Swipe"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Pro 2", family: "FreeBuds Pro", driverName: "FreeBuds Pro 2 Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Pro 3", family: "FreeBuds Pro", driverName: "FreeBuds Pro 3 Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Pro 4", family: "FreeBuds Pro", driverName: "FreeBuds Pro 3 Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Pro 5", family: "FreeBuds Pro", driverName: "FreeBuds Pro 5 Driver", features: ["ANC", "Battery", "WearDetection", "EQ", "DualConnect", "Gestures", "LowLatency"]),
        SupportedDeviceItem(name: "HUAWEI FreeClip", family: "FreeClip", driverName: "FreeBuds Pro 3 Driver", features: ["Battery", "WearDetection", "DualConnect", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeClip 2", family: "FreeClip", driverName: "FreeClip 2 Driver", features: ["Battery", "WearDetection", "DualConnect", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds SE", family: "FreeBuds SE", driverName: "FreeBuds SE Driver", features: ["Battery", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds SE 2", family: "FreeBuds SE", driverName: "FreeBuds SE 2 Driver", features: ["Battery", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds SE 4 ANC", family: "FreeBuds SE", driverName: "FreeBuds SE 4 Driver", features: ["ANC", "Battery", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeBuds Studio", family: "Studio", driverName: "FreeBuds Studio Driver", features: ["ANC", "Battery", "PowerButton", "Gestures"]),
        SupportedDeviceItem(name: "HUAWEI FreeLace Pro", family: "FreeLace", driverName: "FreeLace Pro Driver", features: ["ANC", "Battery", "AutoPause"]),
        SupportedDeviceItem(name: "HUAWEI FreeLace Pro 2", family: "FreeLace", driverName: "FreeLace Pro 2 Driver", features: ["ANC", "Battery", "LowLatency", "AutoPause"]),
        SupportedDeviceItem(name: "HONOR Earbuds 2", family: "HONOR", driverName: "FreeBuds 4i Driver", features: ["ANC", "Battery", "Gestures"]),
        SupportedDeviceItem(name: "HONOR Earbuds 2 SE", family: "HONOR", driverName: "FreeBuds 4i Driver", features: ["ANC", "Battery", "Gestures"]),
        SupportedDeviceItem(name: "HONOR Earbuds 2 Lite", family: "HONOR", driverName: "FreeBuds 4i Driver", features: ["ANC", "Battery", "Gestures"])
    ]

    var filteredDevices: [SupportedDeviceItem] {
        devices.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesFamily = selectedFamily == "all" || item.family == selectedFamily
            return matchesSearch && matchesFamily
        }
    }

    var families: [String] {
        let unique = Set(devices.map { $0.family })
        return ["all"] + unique.sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text(L10n.tr("supported_devices_title"))
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(devices.count) \(L10n.tr("devices_count_unit"))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                }
                Text(L10n.tr("supported_devices_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L10n.tr("search_placeholder"), text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))

                // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(families, id: \.self) { family in
                            Button(action: { selectedFamily = family }) {
                                Text(family == "all" ? L10n.tr("filter_all") : family)
                                    .font(.caption)
                                    .fontWeight(selectedFamily == family ? .bold : .medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFamily == family ? Color.blue : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedFamily == family ? .white : .primary)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedFamily == family ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Scrollable List of Devices
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredDevices) { device in
                        HStack(spacing: 14) {
                            Image(systemName: iconForFamily(device.family))
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.blue.opacity(0.1)))

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(device.name)
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(device.features, id: \.self) { feature in
                                            Text(featureBadgeLabel(feature))
                                                .font(.system(size: 10))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.12)))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
    }

    private func iconForFamily(_ family: String) -> String {
        switch family {
        case "FreeBuds Pro", "FreeBuds i", "FreeBuds SE":
            return "headphones"
        case "FreeClip":
            return "ear"
        case "FreeLace", "Studio":
            return "beats.headphones"
        case "HONOR":
            return "wave.3.right"
        default:
            return "computermodem"
        }
    }

    private func featureBadgeLabel(_ feature: String) -> String {
        switch feature {
        case "ANC": return "🔇 ANC"
        case "Battery": return "🔋 Pin"
        case "WearDetection": return "👂 Trạng thái đeo"
        case "EQ": return "🎛️ Equalizer"
        case "DualConnect": return "🔀 Dual-Connect"
        case "Gestures": return "👆 Cử chỉ"
        case "LowLatency": return "⚡ Độ trễ thấp"
        case "AutoPause": return "⏸️ Tự dừng nhạc"
        case "Swipe": return "👈 Vuốt"
        case "PowerButton": return "🔘 Nút nguồn"
        default: return feature
        }
    }
}
