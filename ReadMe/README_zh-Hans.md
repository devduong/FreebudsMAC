<div align="center">

# 🎧 FreebudsMAC

**适用于 macOS 的原生华为 FreeBuds & 荣耀 Earbuds 耳机管理工具**

*纯 Swift & SwiftUI 构建 • 无需 Python 运行环境 • Universal 通用二进制（支持 Apple Silicon 与 Intel）*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20(Ventura%20|%20Sonoma%20|%20Sequoia%20|%20Tahoe)-black?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(arm64%20%2B%20x86__64)-purple?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Release](https://img.shields.io/badge/Version-0.18.0-success?style=flat-square)](https://github.com/devduong/FreebudsMAC/releases)

---

### 🌐 多语言 / Languages / Langues / Языки

[**English**](../README.md) • [**Tiếng Việt**](README_vi.md) • [**简体中文**](README_zh-Hans.md) • [**繁體中文**](README_zh-Hant.md) • [**Русский**](README_ru.md) • [**Français**](README_fr.md)

---

</div>

## ⚠️ 重要说明：仅限 macOS

> [!IMPORTANT]
> **FreebudsMAC 专为 macOS 打造与设计**（支持 macOS 13.0 Ventura、macOS 14 Sonoma、macOS 15 Sequoia 及 macOS Tahoe）。它深度集成 macOS 原生框架（`IOBluetooth`、`CoreBluetooth`、`Carbon.HIToolbox` 及 `UserNotifications`）。
>
> 如果您正在寻找其他操作系统（**Linux** 或 **Windows**）上的支持，请访问由 **@melianmiko** 开发的原始 Python/PyQt 项目：
> 👉 **[https://github.com/melianmiko/OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)**

---

## ✨ 功能特性

- 🎛️ **完整的降噪控制（ANC）**：无缝在 **降噪**、**透传** 以及 **关闭（标准模式）** 之间自由切换。
- 🔋 **实时电量监控**：精准显示左耳、右耳及充电盒的独立电量百分比和充电状态指示。
- 👂 **佩戴检测（自动暂停）**：取下单耳或双耳时自动暂停媒体播放，重新佩戴后自动恢复。
- 🎚️ **均衡器与音效预设**：支持默认、低音增强、高音增强、清晰人声及 10 段自定义均衡器调节。
- 🔀 **双设备连接（Multi-point）**：管理已配对设备，轻松在两台设备之间无缝流转音频。
- 👆 **手势控制自定义**：支持双击、三击、长按及滑动调节音量/曲目。
- ⚡ **低时延游戏模式**：为游戏和视频剪辑开启极低音频延迟模式。
- ⌨️ **全局系统快捷键**：无论当前在使用什么应用程序，均可通过快捷键（`⌥⌘A`、`⌥⌘C`、`⌥⌘0`、`⌥⌘1`、`⌥⌘2`、`⌥⌘L`）即时控制耳机。
- 🔔 **低电量横幅提醒**：原生 macOS 通知提醒，当耳机或充电盒电量降至 20% 和 10% 时发送通知（5 秒后自动淡出）。
- 🚀 **零 Python 依赖**：100% 纯 Swift + SwiftUI 开发，内存与 CPU 占用极低（常驻内存 < 30 MB）。
- 🌐 **多语言支持**：内置英文、越南语、简体中文、繁体中文、俄语和法语。

---

## 🎧 支持的耳机型号

### 官方已适配型号列表

以下型号已经过完整测试，内置独立专属驱动：

| 系列分类 | 具体型号 | 核心功能支持 |
| :--- | :--- | :--- |
| **FreeBuds Pro** | HUAWEI FreeBuds Pro | 降噪、电量、佩戴检测、手势、滑动 |
| | HUAWEI FreeBuds Pro 2 | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| | HUAWEI FreeBuds Pro 3 | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| | HUAWEI FreeBuds Pro 4 | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| | HUAWEI FreeBuds Pro 5 | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| **FreeBuds i** | HUAWEI FreeBuds 4i | 降噪、电量、佩戴检测、手势 |
| | HUAWEI FreeBuds 5i | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| | HUAWEI FreeBuds 6i | 降噪、电量、佩戴检测、均衡器、双设备连接、手势、低时延 |
| **FreeClip** | HUAWEI FreeClip | 电量、佩戴检测、双设备连接、手势 |
| | HUAWEI FreeClip 2 | 电量、佩戴检测、双设备连接、手势 |
| **FreeBuds SE** | HUAWEI FreeBuds SE | 电量、手势 |
| | HUAWEI FreeBuds SE 2 | 电量、手势 |
| | HUAWEI FreeBuds SE 4 ANC | 降噪、电量、手势 |
| **Studio & 颈挂式** | HUAWEI FreeBuds Studio | 降噪、电量、电源键、手势 |
| | HUAWEI FreeLace Pro | 降噪、电量、自动暂停 |
| | HUAWEI FreeLace Pro 2 | 降噪、电量、低时延、自动暂停 |
| **HONOR** | HONOR Earbuds 2 / 2 SE / 2 Lite | 降噪、电量、手势 |

### 如果您的耳机未在列表中？

FreebudsMAC 拥有智能的**多层级降级兼容机制**：

1. **未列出的华为 / 荣耀蓝牙耳机**：
   - 应用程序会自动启用 `GenericHuaweiDriver`（通用驱动程序）。
   - 自动加载标准 SPP 协议处理器（降噪、电量、手势、均衡器、双连接）。
   - 您也可以在**选择设备**页面中关闭*“自动选择已支持的耳机”*，手动选择任意已配对的蓝牙耳机。
2. **第三方 / 非华为品牌耳机**：
   - 由 `BLEBatteryScanner` / `BLEBatteryDriver` 接管。
   - 通过 **Google Fast Pair Specification (`0xFE2C`)** 或标准 **GATT Battery Service (`0x180F`)** 被动读取电量。

---

## 📥 安装与快速上手

### 1. 下载 DMG 安装包
前往 [GitHub Releases](https://github.com/devduong/FreebudsMAC/releases) 页面下载最新的 `FreebudsMAC_Universal_x.x.x.dmg`。

### 2. 安装应用
打开 DMG 文件，将 **FreebudsMAC.app** 拖动至 **应用程序**（`/Applications`）文件夹。

### 3. 首次启动与 macOS Gatekeeper 安全提示

> [!WARNING]
> 由于 FreebudsMAC 为免费开源项目，未购买昂贵的 Apple 开发者签名证书，首次启动时 macOS Gatekeeper 可能会弹出警告：
> *“无法打开 FreebudsMAC，因为无法验证开发者”* 或 *“macOS 无法验证此 App 是否包含恶意软件”*。

打开方法：
1. 打开 Mac 的**系统设置**（System Settings）。
2. 进入**隐私与安全性**（Privacy & Security）。
3. 向下滚动到**安全性**（Security）区域。
4. 点击针对 FreebudsMAC 拦截提示旁的 **“仍要打开”**（Open Anyway）按钮。
5. 在弹出的确认对话框中点击 **“打开”**，并输入 Mac 密码或验证 Touch ID。

*(备用方式：在访达 Finder 中找到 `FreebudsMAC.app`，按住 Control 键点击它并选择 **打开** -> 在弹窗中点击 **打开**)。*

---

## 🛡️ macOS 系统权限设置指南

为了获得完整的体验，建议在 **FreebudsMAC 设置 > macOS 设置** 中配置必要权限：

```
FreebudsMAC 设置 ➔ macOS 设置
├── 1. 蓝牙访问权限     ➔ 必需（扫描并与 FreeBuds 耳机通信）
├── 2. 通知权限         ➔ 低电量提醒（建议将提醒样式设为横幅）
└── 3. 辅助功能权限     ➔ 全局快捷键监听（在后台响应按键）
```

### 1. 🔵 蓝牙访问权限
- **用途**：通过 SPP/RFCOMM 和 BLE 链路与耳机通信，读取电量与发送控制指令。
- **授权方式**：首次启动点击弹窗中的“允许”，或在设置中点击“打开蓝牙设置”。

### 2. 🔔 通知权限（低电量提醒）
- **用途**：在耳机或充电盒电量降至 20% 和 10% 时发送系统通知（5 秒后自动淡出，不打扰屏幕）。
- **重要配置**：
  - 进入 macOS **系统设置** -> **通知** -> **FreebudsMAC**。
  - 将**提醒样式**设为**横幅**（Banners）而非“无”，确保通知能在屏幕右上角正常弹出。

### 3. ⌨️ 辅助功能权限（全局快捷键）
- **用途**：用于在应用最小化或常驻菜单栏时，在后台监听全局快捷键。
- **授权方式**：点击设置中的“授予辅助功能权限”，系统将打开 **隐私与安全性 > 辅助功能**，勾选并开启 **FreebudsMAC**。

#### 支持的全局快捷键列表：

| 快捷键 | 功能 | 说明 |
| :---: | :--- | :--- |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>A</kbd> | **循环切换降噪** | 在 关闭 ➔ 降噪 ➔ 透传 之间循环 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>C</kbd> | **连接 / 断开** | 一键连接或断开耳机 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>0</kbd> | **关闭降噪** | 切换至普通模式（关闭 ANC） |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>1</kbd> | **开启降噪** | 切换至主动降噪模式 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>2</kbd> | **开启透传** | 切换至环境音透传模式 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>L</kbd> | **低时延模式** | 开启/关闭游戏低延迟模式 |

---

## 🛠️ 从源码编译

### 环境要求
- macOS 13.0 (Ventura) 或更高版本（推荐 macOS Sonoma / Sequoia / Tahoe）。
- Xcode Command Line Tools (`xcode-select --install`)，Swift 5.9+。

### 编译与运行
```bash
# 1. 克隆代码仓库
git clone https://github.com/devduong/FreebudsMAC.git
cd FreebudsMAC

# 2. 以 Release 模式编译
swift build -c release

# 3. 运行应用程序
swift run FreebudsMAC
```

---

## 🙏 致谢与鸣谢

- 衷心感谢 **[@melianmiko](https://github.com/melianmiko)** 创立了最初的 **[OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)** Python/PyQt 项目，对华为蓝牙 SPP 协议进行详细记录与指令逆向。
- 感谢开源社区在逆向华为/荣耀蓝牙协议及 Fast Pair 格式方面所作出的贡献。

---

## ☕ 赞助与支持

FreebudsMAC 是在 GPL-3.0 许可证下发布的 100% 免费开源项目。如果该项目改善了您在 Mac 上使用华为耳机的体验，欢迎赞助支持本项目的持续维护与新功能开发：

<div align="center">

[![Support on Ko-fi](https://img.shields.io/badge/Support_on-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/X4P324ZPZ3)
[![Star on GitHub](https://img.shields.io/badge/Star_on-GitHub-yellow?style=for-the-badge&logo=github&logoColor=black)](https://github.com/devduong/FreebudsMAC)

</div>

### 🪙 加密货币赞助 (BEP20 / 币安智能链)

您可以向以下钱包地址转入任何 BEP20 代币（USDT、BNB、BUSD、ETH、BTC 等）：

```text
网络   : BEP20 (BSC – Binance Smart Chain)
钱包地址 : 0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E
```

---

## 📄 开源许可证

本项目基于 [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html) 开源许可证。
