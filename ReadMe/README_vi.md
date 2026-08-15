<div align="center">

# 🎧 FreebudsMAC

**Ứng dụng Quản lý Tai nghe HUAWEI FreeBuds & HONOR Earbuds Native trên macOS**

*Viết hoàn toàn bằng Swift & SwiftUI • Không phụ thuộc Python Runtime • Universal Binary (Apple Silicon & Intel)*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B%20(Ventura%20|%20Sonoma%20|%20Sequoia%20|%20Tahoe)-black?style=flat-square&logo=apple)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%206.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Kiến_trúc-Universal%20(arm64%20%2B%20x86__64)-purple?style=flat-square)](#)
[![License](https://img.shields.io/badge/Giấy_phép-GPL--3.0-blue?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)
[![Release](https://img.shields.io/badge/Phiên_bản-0.18.0-success?style=flat-square)](https://github.com/devduong/FreebudsMAC/releases)

---

### 🌐 Ngôn ngữ / Languages / 多语言 / Языки / Langues

[**English**](../README.md) • [**Tiếng Việt**](README_vi.md) • [**简体中文**](README_zh-Hans.md) • [**繁體中文**](README_zh-Hant.md) • [**Русский**](README_ru.md) • [**Français**](README_fr.md)

---

</div>

## ⚠️ Lưu ý Quan trọng: Chỉ Hỗ trợ macOS

> [!IMPORTANT]
> **FreebudsMAC được xây dựng và tối ưu hóa 100% dành riêng cho hệ điều hành macOS** (yêu cầu từ macOS 13.0 Ventura trở lên, hỗ trợ hoàn hảo trên macOS 14 Sonoma, macOS 15 Sequoia và macOS Tahoe). Ứng dụng khai thác trực tiếp các framework native của Apple như `IOBluetooth`, `CoreBluetooth`, `Carbon.HIToolbox` và `UserNotifications`.
>
> Nếu bạn đang sử dụng hệ điều hành khác như **Linux** hoặc **Windows**, vui lòng truy cập repository gốc (viết bằng Python/PyQt) của tác giả **@melianmiko**:
> 👉 **[https://github.com/melianmiko/OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)**

---

## ✨ Tính năng Nổi bật

- 🎛️ **Điều khiển Chống ồn Chủ động (ANC) Toàn diện**: Chuyển đổi nhanh chóng giữa **Chống ồn (Noise Cancellation)**, **Xuyên âm / Nhận biết (Awareness)** và **Tắt (Normal)**.
- 🔋 **Theo dõi Phần trăm Pin Thời gian Thực**: Hiển thị chính xác % pin Tai Trái (L), Tai Phải (R) và Hộp Sạc (Case) kèm biểu tượng trạng thái đang sạc.
- 👂 **Tự Động Nhận diện Đeo Tai (In-Ear Detection)**: Tự động tạm dừng phát nhạc khi tháo tai nghe và tiếp tục phát khi đeo lại.
- 🎚️ **Bộ Chỉnh Âm (Equalizer) & Cấu hình Âm thanh**: Đổi nhanh các cấu hình âm thanh Mặc định, Tăng âm trầm (Bass Boost), Tăng âm bổng (Treble Boost), Giọng hát (Voices) và các tuỳ chỉnh EQ cá nhân.
- 🔀 **Kết nối Đôi (Dual-Connect / Multi-point)**: Quản lý danh sách thiết bị đã ghép nối và chuyển đổi nhanh luồng âm thanh giữa các thiết bị.
- 👆 **Tùy chỉnh Cử chỉ Cảm ứng (Touch Gestures)**: Cài đặt hành động khi Chạm 2 lần, Chạm 3 lần, Nhấn giữ và Vuốt điều chỉnh âm lượng.
- ⚡ **Chế độ Độ Trễ Thấp (Low Latency Gaming Mode)**: Giảm tối đa độ trễ truyền âm thanh khi chơi game hoặc dựng video.
- ⌨️ **Phím tắt Toàn Hệ thống (Global Hotkeys)**: Bộ phím tắt tiện lợi (`⌥⌘A`, `⌥⌘C`, `⌥⌘0`, `⌥⌘1`, `⌥⌘2`, `⌥⌘L`) hoạt động nhạy bén ngay cả khi app đang chạy ẩn dưới khay Menu Bar.
- 🔔 **Thông báo Pin Yếu Tự Động Ẩn**: Gửi banner thông báo native khi pin tai nghe còn 20% và 10% (tự động biến mất sau 5 giây không làm phiền màn hình).
- 🚀 **Hiệu năng Vượt trội**: Ứng dụng native siêu nhẹ, khởi động tức thì, tiêu thụ RAM dưới 30 MB và gần như 0% CPU.
- 🌐 **Đa ngôn ngữ Linh hoạt**: Hỗ trợ sẵn Tiếng Việt, Tiếng Anh (English), Tiếng Trung Giản Thể (简体中文), Tiếng Trung Phồn Thể (繁體中文), Tiếng Nga (Русский) và Tiếng Pháp (Français).

---

## 🎧 Danh Sách Tai Nghe Hỗ Trợ

### Các dòng tai nghe hỗ trợ chính thức (Đầy đủ tính năng)

Các dòng tai nghe dưới đây đã được kiểm thử và tích hợp driver điều khiển chuyên biệt:

| Phân dòng | Tên dòng tai nghe | Các tính năng hỗ trợ |
| :--- | :--- | :--- |
| **FreeBuds Pro** | HUAWEI FreeBuds Pro | ANC, Pin, Trạng thái đeo, Cử chỉ, Vuốt âm lượng |
| | HUAWEI FreeBuds Pro 2 | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| | HUAWEI FreeBuds Pro 3 | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| | HUAWEI FreeBuds Pro 4 | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| | HUAWEI FreeBuds Pro 5 | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| **FreeBuds i** | HUAWEI FreeBuds 4i | ANC, Pin, Trạng thái đeo, Cử chỉ |
| | HUAWEI FreeBuds 5i | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| | HUAWEI FreeBuds 6i | ANC, Pin, Trạng thái đeo, Equalizer, Dual-Connect, Cử chỉ, Độ trễ thấp |
| **FreeClip** | HUAWEI FreeClip | Pin, Trạng thái đeo, Dual-Connect, Cử chỉ |
| | HUAWEI FreeClip 2 | Pin, Trạng thái đeo, Dual-Connect, Cử chỉ |
| **FreeBuds SE** | HUAWEI FreeBuds SE | Pin, Cử chỉ |
| | HUAWEI FreeBuds SE 2 | Pin, Cử chỉ |
| | HUAWEI FreeBuds SE 4 ANC | ANC, Pin, Cử chỉ |
| **Studio & Neckband** | HUAWEI FreeBuds Studio | ANC, Pin, Nút nguồn, Cử chỉ |
| | HUAWEI FreeLace Pro | ANC, Pin, Tự dừng nhạc (Nam châm) |
| | HUAWEI FreeLace Pro 2 | ANC, Pin, Độ trễ thấp, Tự dừng nhạc |
| **HONOR** | HONOR Earbuds 2 / 2 SE / 2 Lite | ANC, Pin, Cử chỉ |

### Đối với các dòng tai nghe khác thì sao?

FreebudsMAC được trang bị **cơ chế Fallback thông minh 3 tầng** xử lý mượt mà cho mọi trường hợp:

1. **Tai nghe HUAWEI / HONOR chưa có trong danh sách**:
   - Ứng dụng tự động khởi tạo **`GenericHuaweiDriver`**.
   - Driver này nạp đầy đủ 100% các bộ xử lý SPP tiêu chuẩn (ANC, Pin, Cử chỉ, EQ, Dual-Connect).
   - Bạn cũng có thể vào phần **Chọn thiết bị (Device Selection)**, tắt tùy chọn *"Tự động chọn tai nghe được hỗ trợ"* và chọn thủ công bất kỳ tai nghe nào đã ghép nối.
2. **Tai nghe Bluetooth bên thứ ba / Không phải Huawei**:
   - Được xử lý bởi **`BLEBatteryScanner` / `BLEBatteryDriver`**.
   - Ứng dụng sẽ quét dữ liệu thụ động theo chuẩn **Google Fast Pair (`0xFE2C`)** hoặc chuẩn **GATT Battery Service (`0x180F`)** để trích xuất và hiển thị % pin trên khay hệ thống.

---

## 📥 Hướng Dẫn Cài Đặt & Mở Ứng Dụng

### Bước 1: Tải file DMG
Tải file `FreebudsMAC_Universal_x.x.x.dmg` mới nhất tại mục [Releases](https://github.com/devduong/FreebudsMAC/releases).

### Bước 2: Kéo ứng dụng vào Applications
Mở tệp `.dmg` đã tải về và kéo biểu tượng **FreebudsMAC.app** vào thư mục **Applications** (Ứng dụng).

### Bước 3: Cho phép mở ứng dụng trong Cài đặt Bảo mật (Gatekeeper)

> [!WARNING]
> Do FreebudsMAC là phần mềm mã nguồn mở cộng đồng miễn phí và chưa mua chứng chỉ trả phí từ Apple Developer, cơ chế bảo vệ macOS Gatekeeper sẽ hiện cảnh báo khi bạn mở lần đầu:
> *"FreebudsMAC không thể mở vì không thể xác minh nhà phát triển"* hoặc *"macOS không thể xác minh rằng ứng dụng này không có phần mềm độc hại"*.

**Cách mở ứng dụng rất đơn giản:**
1. Mở **System Settings** (Cài đặt hệ thống) trên máy Mac của bạn.
2. Chọn mục **Privacy & Security** (Quyền riêng tư & Bảo mật).
3. Cuộn xuống phần **Security** (Bảo mật).
4. Bạn sẽ thấy dòng chữ thông báo *FreebudsMAC đã bị chặn*. Hãy bấm nút **"Open Anyway" (Mở dù sao đi nữa)**.
5. Khi hộp thoại xác nhận hiện lên, bấm **"Open" (Mở)** và nhập mật khẩu máy hoặc Touch ID.

*(Mẹo nhanh: Bạn cũng có thể nhấn giữ phím `Control` (hoặc nhấp chuột phải) vào `FreebudsMAC.app` trong Finder ➔ Chọn **Open** ➔ Bấm **Open**).*

> [!TIP]
> **Lưu ý trong lần chạy đầu tiên**: Lần chạy đầu tiên có thể chưa hiện % pin ngay do cần đồng bộ luồng Bluetooth (có thể cần cất tai nghe vào hộp sạc rồi lấy ra để kết nối lại); thông tin pin sẽ hiển thị đầy đủ và ổn định ở các lần sau.

---

## 🛡️ Hướng Dẫn Cấp Quyền Hệ Thống

Để ứng dụng phát huy tối đa 100% công năng, hãy mở **Cài đặt FreebudsMAC > Cài đặt macOS** để kiểm tra và cấp 3 quyền cốt lõi:

```
Cài đặt FreebudsMAC ➔ Cài đặt macOS
├── 1. Quyền Bluetooth   ➔ Bắt buộc (Quét & truyền nhận lệnh với tai nghe)
├── 2. Quyền Thông báo   ➔ Báo pin yếu (Nên chọn kiểu Biểu ngữ / Banners)
└── 3. Quyền Trợ năng    ➔ Lắng nghe phím tắt toàn hệ thống khi chạy ẩn
```

### 1. 🔵 Quyền Bluetooth (Bắt buộc)
- **Công dụng**: Kết nối giao tiếp SPP/RFCOMM và BLE để đọc % pin và gửi lệnh đổi chế độ chống ồn.
- **Cách cấp**: Cho phép khi macOS hiện thông báo yêu cầu hoặc bấm *"Mở cài đặt Bluetooth"*.

### 2. 🔔 Quyền Thông báo (Cảnh báo Pin yếu)
- **Công dụng**: Nhận thông báo tự động khi pin tai nghe giảm xuống mức 20% và 10%. Thông báo sẽ tự động biến mất sau 5 giây để không làm phiền màn hình.
- **Lưu ý quan trọng**:
  - Vào **System Settings (Cài đặt hệ thống)** ➔ **Notifications (Thông báo)** ➔ **FreebudsMAC**.
  - Đảm bảo chọn **Kiểu cảnh báo (Alert style)** là **Biểu ngữ (Banners)** thay vì "Không có" (None) để thông báo xuất hiện ở góc màn hình.

### 3. ⌨️ Quyền Trợ Năng (Accessibility - Phím tắt toàn hệ thống)
- **Công dụng**: Cho phép lắng nghe và kích hoạt phím tắt chuyển ANC/âm thanh từ bất kỳ ứng dụng nào khác khi FreebudsMAC đang chạy dưới thanh Menu Bar.
- **Cách cấp**: Bấm nút *"Cấp quyền Trợ năng"* trong app để mở **System Settings > Quyền riêng tư & Bảo mật > Trợ năng**, sau đó bật gạt xanh cho **FreebudsMAC**.

#### Danh sách Phím tắt Mặc định:

| Phím tắt | Tác vụ | Mô tả chi tiết |
| :---: | :--- | :--- |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>A</kbd> | **Chuyển vòng lặp ANC** | Đổi luân phiên giữa Bình thường ➔ Chống ồn ➔ Xuyên âm |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>C</kbd> | **Bật/Ngắt Kết nối** | Kết nối hoặc ngắt kết nối nhanh tai nghe |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>0</kbd> | **Tắt Chống ồn** | Chuyển sang chế độ Bình thường (Tắt ANC) |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>1</kbd> | **Bật Chống ồn** | Kích hoạt Chống ồn Chủ động (ANC On) |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>2</kbd> | **Chế độ Nhận biết** | Kích hoạt Xuyên âm (Awareness / Transparency) |
| <kbd>⌥ Option</kbd> + <kbd>⌘ Cmd</kbd> + <kbd>L</kbd> | **Độ trễ Thấp** | Bật chế độ Âm thanh Độ trễ thấp khi chơi game |

---

## 🛠️ Tự Biên Dịch Từ Mã Nguồn (Dành cho Lập trình viên)

### Yêu cầu môi trường
- macOS 13.0 (Ventura) trở lên (khuyên dùng macOS Sonoma / Sequoia / Tahoe).
- Xcode Command Line Tools (`xcode-select --install`) với Swift 5.9+.

### Các lệnh biên dịch và chạy
```bash
# 1. Clone mã nguồn dự án
git clone https://github.com/devduong/FreebudsMAC.git
cd FreebudsMAC

# 2. Biên dịch bản Release
swift build -c release

# 3. Khởi chạy ứng dụng
swift run FreebudsMAC
```

---

## 🙏 Cảm Ơn & Tri Ân

- Xin gửi lời cảm ơn chân thành và sâu sắc nhất đến **[@melianmiko](https://github.com/melianmiko)** - tác giả của dự án gốc **[OpenFreebuds](https://github.com/melianmiko/OpenFreebuds)** bằng Python/PyQt. Các tài liệu phân tích giao thức SPP Huawei, cấu trúc gói tin và thông số reverse-engineering của anh là nền tảng vô giá giúp hiện thực hóa phiên bản Swift native này.
- Cảm ơn cộng đồng mã nguồn mở đã cùng đóng góp phân tích các gói tin Bluetooth của Huawei/Honor và giao thức Fast Pair.

---

## ☕ Ủng Hộ & Quyên Góp (Donate)

FreebudsMAC là phần mềm hoàn toàn miễn phí và mã nguồn mở theo giấy phép GPL-3.0. Nếu ứng dụng mang lại tiện ích cho bạn khi dùng tai nghe HUAWEI trên máy Mac, bạn có thể ủng hộ tác giả để duy trì dự án và phát triển thêm các tính năng mới:

<div align="center">

[![Support on Ko-fi](https://img.shields.io/badge/Support_on-Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/X4P324ZPZ3)
[![Star on GitHub](https://img.shields.io/badge/Star_on-GitHub-yellow?style=for-the-badge&logo=github&logoColor=black)](https://github.com/devduong)

</div>

### 🪙 Quyên góp qua Crypto (BEP20 / Binance Smart Chain)

Bạn có thể chuyển bất kỳ token chuẩn BEP20 nào (USDT, BNB, BUSD, ETH, BTC...) tới địa chỉ ví:

```text
Mạng lưới (Network) : BEP20 (BSC – Binance Smart Chain)
Địa chỉ ví (Address): 0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E
```

---

## 📄 Giấy Phép (License)

Dự án được phân phối theo [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
