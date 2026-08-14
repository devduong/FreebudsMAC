<div align="center">

# 🎧 FreebudsMAC

**Native macOS Manager for HUAWEI FreeBuds & HONOR Earbuds**

*Pure Swift & SwiftUI • No Python Runtime • Universal Binary (Apple Silicon & Intel)*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20(Ventura%20|%20Sonoma%20|%20Sequoia%20|%20Tahoe)-black?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(arm64%20%2B%20x86__64)-purple?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Release](https://img.shields.io/badge/Version-0.18.0-success?style=flat-square)](https://github.com/devduong/FreebudsMAC/releases)

---

### 🌐 Languages / Ngôn ngữ / Языки / Langues

[**English**](../README.md) • [**Tiếng Việt**](README_vi.md) • [**Русский**](README_ru.md) • [**Français**](README_fr.md)

---

</div>

## ⚠️ Important: macOS Only

> [!IMPORTANT]
> **FreebudsMAC is exclusively built and designed for macOS** (macOS 13.0 Ventura, macOS 14 Sonoma, macOS 15 Sequoia, and macOS Tahoe). It utilizes macOS native frameworks (`IOBluetooth`, `CoreBluetooth`, `Carbon.HIToolbox`, and `UserNotifications`).
>
> If you are looking for support on other operating systems (**Linux** or **Windows**), please visit the original Python/PyQt project by **@melianmiko**:
> 👉 **[https://github.com/melianmiko/OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)**

---

## ✨ Features

- 🎛️ **Full Active Noise Cancellation (ANC) Control**: Seamlessly toggle between **Noise Cancellation**, **Awareness (Transparency)**, and **Off (Normal)**.
- 🔋 **Live Battery Monitoring**: Accurate battery percentages for Left Earbud, Right Earbud, and Charging Case with charging status indicators.
- 👂 **In-Ear Detection (Auto-Pause)**: Automatically pauses playback when removing earbuds and resumes when put back.
- 🎚️ **Equalizer & Sound Profiles**: Switch between Default, Bass Boost, Treble Boost, Voices, and custom EQ presets.
- 🔀 **Dual-Connect (Multi-point)**: Manage connected devices and quickly transfer active connection between paired devices.
- 👆 **Touch & Gesture Customization**: Configure Double Tap, Triple Tap, Long Press, and Swipe gestures (volume / track control).
- ⚡ **Low Latency Gaming Mode**: Enable low latency audio streaming for gaming and video editing.
- ⌨️ **Global System Hotkeys**: Instant hotkeys (`⌥⌘A`, `⌥⌘C`, `⌥⌘0`, `⌥⌘1`, `⌥⌘2`, `⌥⌘L`) that work from anywhere across macOS.
- 🔔 **Low Battery Notifications**: Native time-sensitive notification banners at 20% and 10% battery levels (auto-dismisses after 3 seconds).
- 🚀 **Zero Python Dependencies**: 100% native Swift & SwiftUI application with minimal CPU and RAM usage (< 30 MB).
- 🌐 **Multi-language Support**: Built-in English, Vietnamese (Tiếng Việt), Russian (Русский), and French (Français).

---

## 🎧 Supported Devices

### Officially Supported Models

The following devices are tested and natively mapped with dedicated drivers:

| Model Family | Earbuds Model | Key Features |
| :--- | :--- | :--- |
| **FreeBuds Pro** | HUAWEI FreeBuds Pro | ANC, Battery, Wear Detection, Gestures, Swipe |
| | HUAWEI FreeBuds Pro 2 | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| | HUAWEI FreeBuds Pro 3 | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| | HUAWEI FreeBuds Pro 4 | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| | HUAWEI FreeBuds Pro 5 | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| **FreeBuds i** | HUAWEI FreeBuds 4i | ANC, Battery, Wear Detection, Gestures |
| | HUAWEI FreeBuds 5i | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| | HUAWEI FreeBuds 6i | ANC, Battery, Wear Detection, EQ, Dual-Connect, Gestures, Low Latency |
| **FreeClip** | HUAWEI FreeClip | Battery, Wear Detection, Dual-Connect, Gestures |
| | HUAWEI FreeClip 2 | Battery, Wear Detection, Dual-Connect, Gestures |
| **FreeBuds SE** | HUAWEI FreeBuds SE | Battery, Gestures |
| | HUAWEI FreeBuds SE 2 | Battery, Gestures |
| | HUAWEI FreeBuds SE 4 ANC | ANC, Battery, Gestures |
| **Studio & Neckband** | HUAWEI FreeBuds Studio | ANC, Battery, Power Button, Gestures |
| | HUAWEI FreeLace Pro | ANC, Battery, Auto-Pause |
| | HUAWEI FreeLace Pro 2 | ANC, Battery, Low Latency, Auto-Pause |
| **HONOR** | HONOR Earbuds 2 / 2 SE / 2 Lite | ANC, Battery, Gestures |

### What About Other / Unlisted Models?

FreebudsMAC includes an intelligent **multi-tier fallback system**:

1. **Unlisted HUAWEI / HONOR Earbuds**:
   - If your model is not explicitly listed, the app automatically initializes `GenericHuaweiDriver`.
   - It automatically loads standard SPP packet handlers (ANC, Battery, Gestures, EQ, Dual-Connect).
   - You can also go to **Device Selection**, turn off *"Auto-select supported earbuds"*, and manually select any paired Bluetooth device.
2. **Third-Party / Non-Huawei Earbuds**:
   - Handled via `BLEBatteryScanner` / `BLEBatteryDriver`.
   - Reads battery levels passively using **Google Fast Pair Specification (`0xFE2C`)** or standard **GATT Battery Service (`0x180F`)**.

---

## 📥 Installation & Setup

### 1. Download DMG
Download the latest `FreebudsMAC_Universal_x.x.x.dmg` from [GitHub Releases](https://github.com/devduong/FreebudsMAC/releases).

### 2. Install App
Open the DMG and drag **FreebudsMAC.app** into your **Applications** (`/Applications`) folder.

### 3. First Launch & macOS Gatekeeper Bypass

> [!WARNING]
> Because FreebudsMAC is a free open-source project and is not signed with a paid Apple Developer certificate, macOS Gatekeeper may show a warning:
> *"FreebudsMAC cannot be opened because the developer cannot be verified"* or *"macOS cannot verify that this app is free from malware"*.

To open the app:
1. Open **System Settings** (Cài đặt hệ thống) on your Mac.
2. Go to **Privacy & Security** (Quyền riêng tư & Bảo mật).
3. Scroll down to the **Security** (Bảo mật) section.
4. Click the **"Open Anyway"** (Mở dù sao đi nữa) button next to the notification that FreebudsMAC was blocked.
5. In the confirmation dialog, click **"Open"** and enter your Mac password or use Touch ID.

*(Alternative: Right-click / Control-click `FreebudsMAC.app` in Finder -> select **Open** -> click **Open**).*

---

## 🛡️ macOS Permissions Guide

For the best experience, configure the necessary permissions in **FreebudsMAC Settings > macOS Settings**:

```
FreebudsMAC Settings ➔ macOS Settings
├── 1. Bluetooth Permission     ➔ Required (Scan & communicate with FreeBuds)
├── 2. Notifications Permission ➔ Low battery alerts (Set alert style to Banners)
└── 3. Accessibility Permission ➔ Global Hotkeys listener
```

### 1. 🔵 Bluetooth Permission
- **Purpose**: Essential for connecting to your earbuds over SPP/RFCOMM and BLE channels to read battery levels and send commands.
- **How to grant**: Click *"Open Bluetooth Settings"* or allow when macOS prompts on first launch.

### 2. 🔔 Notification Permission (Low Battery Alerts)
- **Purpose**: Receive alerts when battery drops to 20% and 10%. Alerts automatically disappear after 3 seconds so they don't clutter your screen.
- **Important Configuration**:
  - Go to macOS **System Settings** -> **Notifications** -> **FreebudsMAC**.
  - Set **Alert style** to **Banners** (Biểu ngữ) instead of "None" to ensure popups appear in the top right corner.

### 3. ⌨️ Accessibility Permission (Global Hotkeys)
- **Purpose**: Required by macOS to monitor global keyboard shortcuts even when FreebudsMAC is running in the background/menu bar.
- **How to grant**: Click *"Grant Accessibility Permission"* in app settings, which opens **System Settings > Privacy & Security > Accessibility**. Toggle on **FreebudsMAC**.

#### Available Global Hotkeys:

| Shortcut | Action | Description |
| :---: | :--- | :--- |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>A</kbd> | **Cycle ANC Mode** | Switch between Normal ➔ ANC ➔ Awareness |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>C</kbd> | **Toggle Connection** | Connect or disconnect earbuds |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>0</kbd> | **Disable Noise Control** | Normal Mode (ANC Off) |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>1</kbd> | **Enable ANC** | Active Noise Cancellation Mode |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>2</kbd> | **Enable Awareness** | Transparency / Awareness Mode |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>L</kbd> | **Low Latency Mode** | Gaming / Low Audio Delay Mode |

---

## 🛠️ Building from Source

### Prerequisites
- macOS 13.0 (Ventura) or later (macOS Sonoma / Sequoia / Tahoe recommended).
- Xcode Command Line Tools (`xcode-select --install`) with Swift 5.9+.

### Build & Run
```bash
# 1. Clone repository
git clone https://github.com/devduong/FreebudsMAC.git
cd FreebudsMAC

# 2. Build in Release mode
swift build -c release

# 3. Run the application
swift run FreebudsMAC
```

---

## 🙏 Special Thanks & Acknowledgements

- Deep appreciation to **[@melianmiko](https://github.com/melianmiko)** for creating the original **[OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)** project in Python/PyQt, documenting the Huawei Bluetooth SPP protocol, and reverse-engineering the command packet specifications.
- Thanks to the open-source community for reverse engineering Huawei/Honor Bluetooth packets and Fast Pair protocol formats.

---

## ☕ Support & Donation

FreebudsMAC is 100% free and open-source software under the GPL-3.0 License. If this project makes your daily Mac experience with HUAWEI FreeBuds smoother, please consider supporting its continued maintenance and new feature development:

<div align="center">

[![Support on Ko-fi](https://img.shields.io/badge/Support_on-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/X4P324ZPZ3)
[![Star on GitHub](https://img.shields.io/badge/Star_on-GitHub-yellow?style=for-the-badge&logo=github&logoColor=black)](https://github.com/devduong)

</div>

### 🪙 Crypto Donation (BEP20 / Binance Smart Chain)

You can send any BEP20 tokens (USDT, BNB, BUSD, ETH, BTC, etc.) to the following wallet address:

```text
Network : BEP20 (BSC – Binance Smart Chain)
Address : 0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E
```

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
