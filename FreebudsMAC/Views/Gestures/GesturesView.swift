// OpenFreebuds/Views/Gestures/GesturesView.swift

import SwiftUI
import OFBCore

struct GesturesView: View {
    @ObservedObject var manager: DeviceManager

    @State private var doubleTapLeft: String = "tap_action_pause"
    @State private var doubleTapRight: String = "tap_action_pause"
    @State private var tripleTapLeft: String = "tap_action_next"
    @State private var tripleTapRight: String = "tap_action_prev"
    @State private var longTapLeft: String = "tap_action_switch_anc"
    @State private var longTapRight: String = "tap_action_switch_anc"
    @State private var swipeGesture: String = "tap_action_change_volume"

    var gestureActions: [(id: String, name: String)] {[
        ("tap_action_pause", L10n.tr("gesture_pause")),
        ("tap_action_next", L10n.tr("gesture_next")),
        ("tap_action_prev", L10n.tr("gesture_prev")),
        ("tap_action_assistant", L10n.tr("gesture_assistant")),
        ("tap_action_switch_anc", L10n.tr("gesture_switch_anc")),
        ("tap_action_change_volume", L10n.tr("gesture_change_volume")),
        ("tap_action_off", L10n.tr("gesture_off"))
    ]}

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
                            Text(L10n.tr("not_connected_gesture_hint"))
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

            Section(L10n.tr("double_tap_gestures")) {
                GesturePicker(label: L10n.tr("left_earbud"), selection: $doubleTapLeft, actions: gestureActions) { newValue in
                    updateProperty("double_tap_left", newValue)
                }
                GesturePicker(label: L10n.tr("right_earbud"), selection: $doubleTapRight, actions: gestureActions) { newValue in
                    updateProperty("double_tap_right", newValue)
                }
            }

            Section(L10n.tr("triple_tap_gestures")) {
                GesturePicker(label: L10n.tr("left_earbud"), selection: $tripleTapLeft, actions: gestureActions) { newValue in
                    updateProperty("triple_tap_left", newValue)
                }
                GesturePicker(label: L10n.tr("right_earbud"), selection: $tripleTapRight, actions: gestureActions) { newValue in
                    updateProperty("triple_tap_right", newValue)
                }
            }

            Section(L10n.tr("long_press_gestures")) {
                GesturePicker(label: L10n.tr("left_earbud"), selection: $longTapLeft, actions: gestureActions) { newValue in
                    updateProperty("long_tap_left", newValue)
                }
                GesturePicker(label: L10n.tr("right_earbud"), selection: $longTapRight, actions: gestureActions) { newValue in
                    updateProperty("long_tap_right", newValue)
                }
            }

            Section(L10n.tr("swipe_gesture")) {
                GesturePicker(label: L10n.tr("stem_swipe"), selection: $swipeGesture, actions: gestureActions) { newValue in
                    updateProperty("swipe_gesture", newValue)
                }
            }
        }
        .padding()
        .task {
            await refreshGestures()
            let (id, stream) = await manager.eventBus.subscribe()
            for await _ in stream {
                await refreshGestures()
            }
            await manager.eventBus.unsubscribe(id: id)
        }
    }

    private func updateProperty(_ prop: String, _ value: String) {
        Task {
            try? await manager.setProperty(group: "action", prop: prop, value: value)
        }
    }

    private func refreshGestures() async {
        if let actions = await manager.getProperty(group: "action", prop: nil, fallback: nil) as? [String: String] {
            if let v = actions["double_tap_left"] { self.doubleTapLeft = v }
            if let v = actions["double_tap_right"] { self.doubleTapRight = v }
            if let v = actions["triple_tap_left"] { self.tripleTapLeft = v }
            if let v = actions["triple_tap_right"] { self.tripleTapRight = v }
            if let v = actions["long_tap_left"] { self.longTapLeft = v }
            if let v = actions["long_tap_right"] { self.longTapRight = v }
            if let v = actions["swipe_gesture"] { self.swipeGesture = v }
        }
    }
}

struct GesturePicker: View {
    let label: String
    @Binding var selection: String
    let actions: [(id: String, name: String)]
    let onUserChange: (String) -> Void

    var body: some View {
        Picker(label, selection: Binding(
            get: { selection },
            set: { newValue in
                selection = newValue
                onUserChange(newValue)
            }
        )) {
            ForEach(actions, id: \.id) { act in
                Text(act.name).tag(act.id)
            }
        }
    }
}
