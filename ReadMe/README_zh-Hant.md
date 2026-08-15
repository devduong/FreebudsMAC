<div align="center">

# 🎧 FreebudsMAC

**適用於 macOS 的原生華為 FreeBuds & 榮耀 Earbuds 耳機管理工具**

*純 Swift & SwiftUI 建構 • 無需 Python 執行環境 • Universal 通用二進位檔（支援 Apple Silicon 與 Intel）*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20(Ventura%20|%20Sonoma%20|%20Sequoia%20|%20Tahoe)-black?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(arm64%20%2B%20x86__64)-purple?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Release](https://img.shields.io/badge/Version-0.18.0-success?style=flat-square)](https://github.com/devduong/FreebudsMAC/releases)

---

### 🌐 多語言 / Languages / Langues / Языки

[**English**](../README.md) • [**Tiếng Việt**](README_vi.md) • [**简体中文**](README_zh-Hans.md) • [**繁體中文**](README_zh-Hant.md) • [**Русский**](README_ru.md) • [**Français**](README_fr.md)

---

</div>

## ⚠️ 重要說明：僅限 macOS

> [!IMPORTANT]
> **FreebudsMAC 專為 macOS 打造與設計**（支援 macOS 13.0 Ventura、macOS 14 Sonoma、macOS 15 Sequoia 及 macOS Tahoe）。它深度整合 macOS 原生框架（`IOBluetooth`、`CoreBluetooth`、`Carbon.HIToolbox` 及 `UserNotifications`）。
>
> 如果您正在尋找其他作業系統（**Linux** 或 **Windows**）上的支援，請造訪由 **@melianmiko** 開發的原始 Python/PyQt 專案：
> 👉 **[https://github.com/melianmiko/OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)**

---

## ✨ 功能特色

- 🎛️ **完整的降噪控制（ANC）**：無縫在 **降噪**、**透傳** 以及 **關閉（標準模式）** 之間自由切換。
- 🔋 **即時電量監控**：精準顯示左耳、右耳及充電盒的獨立電量百分比和充電狀態指示。
- 👂 **佩戴偵測（自動暫停）**：取下單耳或雙耳時自動暫停媒體播放，重新佩戴後自動恢復。
- 🎚️ **等化器與音效預設**：支援預設、低音增強、高音增強、清晰人聲及 10 段自訂等化器調節。
- 🔀 **雙設備連接（Multi-point）**：管理已配對裝置，輕鬆在兩台裝置之間無縫切換音訊。
- 👆 **手勢控制自訂**：支援按兩下、按三下、長按及滑動調節音量/曲目。
- ⚡ **低延遲遊戲模式**：為遊戲和影片剪輯開啟極低音訊延遲模式。
- ⌨️ **全域系統快速鍵**：無論當前在使用什麼應用程式，均可透過快速鍵（`⌥⌘A`、`⌥⌘C`、`⌥⌘0`、`⌥⌘1`、`⌥⌘2`、`⌥⌘L`）即時控制耳機。
- 🔔 **低電量橫幅提醒**：原生 macOS 通知提醒，當耳機或充電盒電量降至 20% 與 10% 時傳送通知（5 秒後自動淡出）。
- 🚀 **零 Python 依賴**：100% 純 Swift + SwiftUI 開發，記憶體與 CPU 佔用極低（常駐記憶體 < 30 MB）。
- 🌐 **多語言支援**：內建英文、越南語、簡體中文、繁體中文、俄語和法語。

---

## 🎧 支援的耳機型號

### 官方已適配型號清單

以下型號已經過完整測試，內建獨立專屬驅動：

| 系列分類 | 具體型號 | 核心功能支援 |
| :--- | :--- | :--- |
| **FreeBuds Pro** | HUAWEI FreeBuds Pro | 降噪、電量、佩戴偵測、手勢、滑動 |
| | HUAWEI FreeBuds Pro 2 | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| | HUAWEI FreeBuds Pro 3 | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| | HUAWEI FreeBuds Pro 4 | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| | HUAWEI FreeBuds Pro 5 | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| **FreeBuds i** | HUAWEI FreeBuds 4i | 降噪、電量、佩戴偵測、手勢 |
| | HUAWEI FreeBuds 5i | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| | HUAWEI FreeBuds 6i | 降噪、電量、佩戴偵測、等化器、雙設備連接、手勢、低延遲 |
| **FreeClip** | HUAWEI FreeClip | 電量、佩戴偵測、雙設備連接、手勢 |
| | HUAWEI FreeClip 2 | 電量、佩戴偵測、雙設備連接、手势 |
| **FreeBuds SE** | HUAWEI FreeBuds SE | 電量、手勢 |
| | HUAWEI FreeBuds SE 2 | 電量、手勢 |
| | HUAWEI FreeBuds SE 4 ANC | 降噪、電量、手勢 |
| **Studio & 頸掛式** | HUAWEI FreeBuds Studio | 降噪、電量、電源鍵、手勢 |
| | HUAWEI FreeLace Pro | 降噪、電量、自動暫停 |
| | HUAWEI FreeLace Pro 2 | 降噪、電量、低延遲、自動暫停 |
| **HONOR** | HONOR Earbuds 2 / 2 SE / 2 Lite | 降噪、電量、手勢 |

### 如果您的耳機未在清單中？

FreebudsMAC 擁有智慧的**多層級降級相容機制**：

1. **未列出的華為 / 榮耀藍牙耳機**：
   - 應用程式會自動啟用 `GenericHuaweiDriver`（通用驅動程式）。
   - 自動載入標準 SPP 協定處理器（降噪、電量、手勢、等化器、雙連接）。
   - 您也可以在**選擇裝置**頁面中關閉*「自動選擇已支援的耳機」*，手動選擇任意已配對的藍牙耳機。
2. **第三方 / 非華為品牌耳機**：
   - 由 `BLEBatteryScanner` / `BLEBatteryDriver` 接管。
   - 透過 **Google Fast Pair Specification (`0xFE2C`)** 或標準 **GATT Battery Service (`0x180F`)** 被動讀取電量。

---

## 📥 安裝與快速上手

### 1. 下載 DMG 安裝檔
前往 [GitHub Releases](https://github.com/devduong/FreebudsMAC/releases) 頁面下載最新的 `FreebudsMAC_Universal_x.x.x.dmg`。

### 2. 安裝應用程式
開啟 DMG 檔案，將 **FreebudsMAC.app** 拖曳至 **應用程式**（`/Applications`）資料夾。

### 3. 首次啟動與 macOS Gatekeeper 安全提示

> [!WARNING]
> 由於 FreebudsMAC 為免費開源專案，未購買昂貴的 Apple 開發者簽名憑證，首次啟動時 macOS Gatekeeper 可能會跳出警告：
> *「無法開啟 FreebudsMAC，因為無法驗證開發者」* 或 *「macOS 無法驗證此 App 是否包含惡意軟體」*。

開啟方法：
1. 開啟 Mac 的**系統設定**（System Settings）。
2. 進入**隱私權與安全性**（Privacy & Security）。
3. 向下捲動到**安全性**（Security）區域。
4. 點擊針對 FreebudsMAC 攔截提示旁的 **「強制開啟」**（Open Anyway）按鈕。
5. 在彈出的確認對話框中點擊 **「開啟」**，並輸入 Mac 密碼或驗證 Touch ID。

*(替代方式：在 Finder 中找到 `FreebudsMAC.app`，按住 Control 鍵點擊它並選擇 **開啟** -> 在彈出視窗中點擊 **開啟**)。*

---

## 🛡️ macOS 系統權限設定指南

為了獲得完整的體驗，建議在 **FreebudsMAC 設定 > macOS 設定** 中配置必要權限：

```
FreebudsMAC 設定 ➔ macOS 設定
├── 1. 藍牙存取權限     ➔ 必需（搜尋並與 FreeBuds 耳機通訊）
├── 2. 通知權限         ➔ 低電量提醒（建議將提醒樣式設為橫幅）
└── 3. 輔助功能權限     ➔ 全域快速鍵監聽（在背景回應按鍵）
```

### 1. 🔵 藍牙存取權限
- **用途**：透過 SPP/RFCOMM 和 BLE 鏈路與耳機通訊，讀取電量與傳送控制指令。
- **授權方式**：首次啟動點擊彈出視窗中的「允許」，或在設定中點擊「開啟藍牙設定」。

### 2. 🔔 通知權限（低電量提醒）
- **用途**：在耳機或充電盒電量降至 20% 與 10% 時傳送系統通知（5 秒後自動淡出，不打擾螢幕）。
- **重要配置**：
  - 進入 macOS **系統設定** -> **通知** -> **FreebudsMAC**。
  - 將**提醒樣式**設為**橫幅**（Banners）而非「無」，確保通知能在螢幕右上角正常顯示。

### 3. ⌨️ 輔助功能權限（全域快速鍵）
- **用途**：用於在應用程式最小化或常駐選單列時，在背景監聽全域快速鍵。
- **授權方式**：點擊設定中的「授予輔助功能權限」，系統將開啟 **隱私權與安全性 > 輔助功能**，勾選並開啟 **FreebudsMAC**。

#### 支援的全域快速鍵清單：

| 快速鍵 | 功能 | 說明 |
| :---: | :--- | :--- |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>A</kbd> | **循環切換降噪** | 在 關閉 ➔ 降噪 ➔ 透傳 之間循環 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>C</kbd> | **連線 / 斷開** | 一鍵連線或斷開耳機 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>0</kbd> | **關閉降噪** | 切換至普通模式（關閉 ANC） |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>1</kbd> | **開啟降噪** | 切換至主動降噪模式 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>2</kbd> | **開啟透傳** | 切換至環境音透傳模式 |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>L</kbd> | **低延遲模式** | 開啟/關閉遊戲低延遲模式 |

---

## 🛠️ 從原始碼編譯

### 環境要求
- macOS 13.0 (Ventura) 或更高版本（推薦 macOS Sonoma / Sequoia / Tahoe）。
- Xcode Command Line Tools (`xcode-select --install`)，Swift 5.9+。

### 編譯與執行
```bash
# 1. 複製程式碼倉庫
git clone https://github.com/devduong/FreebudsMAC.git
cd FreebudsMAC

# 2. 以 Release 模式編譯
swift build -c release

# 3. 執行應用程式
swift run FreebudsMAC
```

---

## 🙏 致謝與鳴謝

- 衷心感謝 **[@melianmiko](https://github.com/melianmiko)** 創立了最初的 **[OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)** Python/PyQt 專案，對華為藍牙 SPP 協定進行詳細記錄與指令逆向。
- 感謝開源社群在逆向華為/榮耀藍牙協定及 Fast Pair 格式方面所作出的貢獻。

---

## ☕ 贊助與支持

FreebudsMAC 是在 GPL-3.0 授權條款下發布的 100% 免費開源專案。如果該專案改善了您在 Mac 上使用華為耳機的體驗，歡迎贊助支持本專案的持續維護與新功能開發：

<div align="center">

[![Support on Ko-fi](https://img.shields.io/badge/Support_on-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/X4P324ZPZ3)
[![Star on GitHub](https://img.shields.io/badge/Star_on-GitHub-yellow?style=for-the-badge&logo=github&logoColor=black)](https://github.com/devduong/FreebudsMAC)

</div>

### 🪙 加密貨幣贊助 (BEP20 / 幣安智慧鏈)

您可以向以下錢包地址轉入任何 BEP20 代幣（USDT、BNB、BUSD、ETH、BTC 等）：

```text
網路   : BEP20 (BSC – Binance Smart Chain)
錢包地址 : 0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E
```

---

## 📄 開源授權條款

本專案基於 [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html) 開源授權條款。
