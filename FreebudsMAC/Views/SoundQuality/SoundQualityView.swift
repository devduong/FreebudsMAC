// OpenFreebuds/Views/SoundQuality/SoundQualityView.swift

import SwiftUI
import OFBCore

struct SoundQualityView: View {
    @ObservedObject var manager: DeviceManager

    @State private var qualityPreference: String = "sqp_quality"
    @State private var selectedPreset: String = "equalizer_preset_default"
    @State private var presetOptions: [String] = ["equalizer_preset_default"]
    @State private var sliderValues: [Double] = Array(repeating: 0.0, count: 10)
    @State private var savedSliderValues: [Double] = Array(repeating: 0.0, count: 10)
    @State private var changesSaved: Bool = true

    private let frequencies = ["31Hz", "62Hz", "125Hz", "250Hz", "500Hz", "1kHz", "2kHz", "4kHz", "8kHz", "16kHz"]

    var body: some View {
        Form {
            if manager.state == .disconnected || manager.state == .failed {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.tr("not_connected_title"))
                                .font(.headline)
                            Text(L10n.tr("not_connected_eq_hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if manager.state == .wait {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.tr("state_wait"))
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                }
            }

            // 1. Sound Quality Priority Mode
            Section(L10n.tr("sound_quality_preference")) {
                Picker(L10n.tr("priority_mode"), selection: Binding(
                    get: { qualityPreference },
                    set: { newValue in
                        qualityPreference = newValue
                        Task {
                            try? await manager.setProperty(group: "sound", prop: "quality_preference", value: newValue)
                        }
                    }
                )) {
                    Text(L10n.tr("prioritize_sound_quality")).tag("sqp_quality")
                    Text(L10n.tr("prioritize_connection")).tag("sqp_connectivity")
                }
                .pickerStyle(.radioGroup)
            }

            // 2. Preset Selection
            Section(L10n.tr("equalizer_presets")) {
                Picker(L10n.tr("preset"), selection: Binding(
                    get: { selectedPreset },
                    set: { newValue in
                        selectedPreset = newValue
                        Task {
                            try? await manager.setProperty(group: "sound", prop: "equalizer_preset", value: newValue)
                            await refreshSoundData()
                        }
                    }
                )) {
                    ForEach(presetOptions, id: \.self) { opt in
                        Text(formatPresetName(opt)).tag(opt)
                    }
                }
            }

            // 3. 10-Band Graphic Equalizer Faders
            Section(L10n.tr("ten_band_equalizer")) {
                // Vertical Fader Rack
                HStack(spacing: 6) {
                    ForEach(0..<10, id: \.self) { idx in
                        VStack(spacing: 8) {
                            Text("\(Int(sliderValues[idx]))dB")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(sliderValues[idx] != 0 ? .accentColor : .secondary)

                            CustomVerticalSlider(value: $sliderValues[idx], onChange: {
                                changesSaved = false
                            })
                            .frame(height: 130)

                            Text(frequencies[idx])
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)

                HStack(spacing: 12) {
                    Button(L10n.tr("save")) {
                        saveEqualizer()
                    }
                    .disabled(changesSaved)

                    Button(L10n.tr("reset")) {
                        sliderValues = Array(repeating: 0.0, count: 10)
                        saveEqualizer()
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .task {
            await refreshSoundData()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshSoundData()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    // MARK: - Helpers

    private func formatPresetName(_ name: String) -> String {
        let key = name.replacingOccurrences(of: "equalizer_preset_", with: "eq_preset_")
        let localized = L10n.tr(key)
        if localized != key { return localized }
        return name.replacingOccurrences(of: "equalizer_preset_", with: "").capitalized
    }

    private func saveEqualizer() {
        let intValues = sliderValues.map { Int($0) }
        if let jsonData = try? JSONSerialization.data(withJSONObject: intValues),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            Task {
                try? await manager.setProperty(group: "sound", prop: "equalizer_rows", value: jsonStr)
                try? await manager.setProperty(group: "sound", prop: "equalizer_saved", value: "true")
            }
            savedSliderValues = sliderValues
            changesSaved = true
        }
    }

    private func refreshSoundData() async {
        if let sound = await manager.getProperty(group: "sound", prop: nil, fallback: nil) as? [String: String] {
            if let pref = sound["quality_preference"] {
                self.qualityPreference = pref
            }
            if let preset = sound["equalizer_preset"] {
                self.selectedPreset = preset
            }
            if let options = sound["equalizer_preset_options"] {
                self.presetOptions = options.components(separatedBy: ",")
            }
            if let rowsStr = sound["equalizer_rows"],
               let rowsData = rowsStr.data(using: .utf8),
               let rows = try? JSONSerialization.jsonObject(with: rowsData) as? [Int],
               rows.count == 10 {
                self.sliderValues = rows.map { Double($0) }
                self.savedSliderValues = self.sliderValues
            }
            if let saved = sound["equalizer_saved"] {
                self.changesSaved = (saved == "true")
            }
        }
    }
}

// MARK: - Custom Native Vertical Slider

struct CustomVerticalSlider: View {
    @Binding var value: Double
    let onChange: () -> Void
    let range: ClosedRange<Double> = -6.0...6.0

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let normalized = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbY = height * (1.0 - normalized)

            ZStack(alignment: .bottom) {
                // Track Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 6)

                // Active Bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(value != 0 ? Color.accentColor : Color.gray.opacity(0.4))
                    .frame(width: 6, height: max(0, height * normalized))

                // Thumb Knob
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .frame(width: 18, height: 18)
                    .position(x: geo.size.width / 2.0, y: thumbY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let locationY = gesture.location.y
                        let clampedY = max(0, min(height, locationY))
                        let percent = 1.0 - (clampedY / height)
                        let val = range.lowerBound + Double(percent) * (range.upperBound - range.lowerBound)
                        let roundedVal = val.rounded()
                        if self.value != roundedVal {
                            self.value = roundedVal
                            onChange()
                        }
                    }
            )
        }
    }
}
