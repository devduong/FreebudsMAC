import Foundation

/// Generic Fallback Driver for any unknown or unlisted HUAWEI / HONOR TWS device.
/// Loads standard set of handlers with automatic probing.
public final class GenericHuaweiDriver: HuaweiDriver, @unchecked Sendable {
    public override init(address: String) {
        super.init(address: address)
        self.sppServicePort = 16 // Default candidate port, fallback loop will probe 18, 1, 2 if needed
        self.handlers = [
            DeviceInfoHandler(),
            InEarStateHandler(),
            ANCHandler(withCancelLevel: true, withCancelDynamic: true, withVoiceBoost: true),
            BatteryHandler(withTws: true),
            DoubleTapHandler(),
            TripleTapHandler(),
            LongTapSplitHandler(wLeft: true, wRight: true),
            SwipeGestureHandler(),
            AutoPauseHandler(),
            LowLatencyHandler(),
            DualConnectHandler(),
            SoundQualityHandler(),
            EqualizerHandler(presets: [1: "default", 2: "hardbass", 3: "treble"])
        ]
    }
}
