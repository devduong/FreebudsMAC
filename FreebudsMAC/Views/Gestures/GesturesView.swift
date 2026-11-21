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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if manager.state == .disconnected || manager.state == .failed {
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
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.12)))
                } else if manager.state == .wait {
                    HStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.small)
                        Text(L10n.tr("state_wait"))
                            .font(.headline)
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
                }

                // 1. Double Tap
                GestureCard(title: L10n.tr("double_tap_gestures"), icon: "hand.tap.fill") {
                    GestureRow(label: L10n.tr("left_earbud"), selection: $doubleTapLeft, actions: gestureActions) { newValue in
                        updateProperty("double_tap_left", newValue)
                    }
                    Divider().opacity(0.5)
                    GestureRow(label: L10n.tr("right_earbud"), selection: $doubleTapRight, actions: gestureActions) { newValue in
                        updateProperty("double_tap_right", newValue)
                    }
                }

                // 2. Triple Tap
                GestureCard(title: L10n.tr("triple_tap_gestures"), icon: "hand.point.up.braille.fill") {
                    GestureRow(label: L10n.tr("left_earbud"), selection: $tripleTapLeft, actions: gestureActions) { newValue in
                        updateProperty("triple_tap_left", newValue)
                    }
                    Divider().opacity(0.5)
                    GestureRow(label: L10n.tr("right_earbud"), selection: $tripleTapRight, actions: gestureActions) { newValue in
                        updateProperty("triple_tap_right", newValue)
                    }
                }

                // 3. Long Press
                GestureCard(title: L10n.tr("long_press_gestures"), icon: "hand.draw.fill") {
                    GestureRow(label: L10n.tr("left_earbud"), selection: $longTapLeft, actions: gestureActions) { newValue in
                        updateProperty("long_tap_left", newValue)
                    }
                    Divider().opacity(0.5)
                    GestureRow(label: L10n.tr("right_earbud"), selection: $longTapRight, actions: gestureActions) { newValue in
                        updateProperty("long_tap_right", newValue)
                    }
                }

                // 4. Swipe
                GestureCard(title: L10n.tr("swipe_gesture"), icon: "arrow.up.and.down.circle.fill") {
                    GestureRow(label: L10n.tr("stem_swipe"), selection: $swipeGesture, actions: gestureActions) { newValue in
                        updateProperty("swipe_gesture", newValue)
                    }
                }
            }
            .padding(20)
        }
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

private struct GestureCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            Divider()
            content
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }
}

private struct GestureRow: View {
    let label: String
    @Binding var selection: String
    let actions: [(id: String, name: String)]
    let onUserChange: (String) -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Picker("", selection: Binding(
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
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 240)
        }
    }
}
