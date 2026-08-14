// OpenFreebuds/Helpers/GlobalHotkeyManager.swift
// Port of openfreebuds_qt/utils/hotkeys/ (Carbon RegisterEventHotKey + NSEvent global hotkeys)

import Foundation
import AppKit
import Carbon.HIToolbox
import OFBCore

public final class GlobalHotkeyManager: @unchecked Sendable {
    public static let shared = GlobalHotkeyManager()

    private weak var manager: DeviceManager?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandlerRef: EventHandlerRef?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    public func setup(manager: DeviceManager) {
        self.manager = manager
        unregisterHotKeys()
        registerCarbonHotKeys()
        registerNSEventMonitors()
    }

    private func registerCarbonHotKeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handlerProc: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr {
                let this = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                this.handleHotKeyID(hotKeyID.id)
            }
            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handlerProc, 1, &eventType, selfPtr, &eventHandlerRef)

        let cmdOpt = UInt32(cmdKey | optionKey)

        let shortcuts: [(id: UInt32, code: UInt32)] = [
            (1, 0),  // 'A' -> Cycle ANC
            (2, 8),  // 'C' -> Toggle Connect
            (3, 29), // '0' -> ANC Off
            (4, 18), // '1' -> ANC Cancellation
            (5, 19), // '2' -> ANC Awareness
            (6, 37)  // 'L' -> Low Latency
        ]

        for s in shortcuts {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: OSType(0x4F464248), id: s.id) // "OFBH"
            let status = RegisterEventHotKey(s.code, cmdOpt, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
            if status == noErr {
                hotKeyRefs.append(hotKeyRef)
                NSLog("[OFB-Hotkey] ✅ Registered Carbon HotKey ID %d (KeyCode %d)", s.id, s.code)
            } else {
                NSLog("[OFB-Hotkey] ⚠️ Failed to register Carbon HotKey ID %d (status %d)", s.id, status)
            }
        }
    }

    private func registerNSEventMonitors() {
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleNSEvent(event)
            }
        }
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                self?.handleNSEvent(event)
                return event
            }
        }
    }

    private func handleHotKeyID(_ id: UInt32) {
        Task { @MainActor [weak self] in
            guard let mgr = self?.manager else { return }
            NSLog("[OFB-Hotkey] 🎹 HotKey triggered ID: %d", id)
            switch id {
            case 1: try? await mgr.shortcuts.execute(.nextMode)
            case 2: try? await mgr.shortcuts.execute(.toggleConnect)
            case 3: try? await mgr.shortcuts.execute(.modeNormal)
            case 4: try? await mgr.shortcuts.execute(.modeCancellation)
            case 5: try? await mgr.shortcuts.execute(.modeAwareness)
            case 6: try? await mgr.shortcuts.execute(.enableLowLatency)
            default: break
            }
        }
    }

    private func handleNSEvent(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.option) && flags.contains(.command) {
            Task { @MainActor [weak self] in
                guard let mgr = self?.manager else { return }
                switch event.keyCode {
                case 0:  try? await mgr.shortcuts.execute(.nextMode)
                case 8:  try? await mgr.shortcuts.execute(.toggleConnect)
                case 29: try? await mgr.shortcuts.execute(.modeNormal)
                case 18: try? await mgr.shortcuts.execute(.modeCancellation)
                case 19: try? await mgr.shortcuts.execute(.modeAwareness)
                case 37: try? await mgr.shortcuts.execute(.enableLowLatency)
                default: break
                }
            }
        }
    }

    private func unregisterHotKeys() {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }

    deinit {
        unregisterHotKeys()
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
    }
}
