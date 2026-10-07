# 🏢 Apartment Management - Ứng Dụng Di Động Dành Cho Cư Dân (Resident App)

Ứng dụng di động quản lý chung cư hiện đại được phát triển bằng **Flutter**, tối ưu hóa trải nghiệm số hóa cho Cư dân sinh sống tại tòa nhà: tra cứu hóa đơn, thanh toán online tự động qua **VNPAY**, theo dõi hợp đồng, quản lý phương tiện, đăng ký vận chuyển, gửi yêu cầu bảo trì và nhận thông báo tức thời.

---

## 📱 Tính Năng Chính

* 🔐 **Xác thực & Bảo mật**: Đăng nhập tài khoản cư dân với JWT Authentication, tự động lưu phiên và xử lý làm mới phiên đăng nhập.
* 💳 **Thanh toán Hóa đơn Trực tuyến VNPAY (1-Click Workflow)**:
  * Xem danh sách hóa đơn theo trạng thái (*Chưa thanh toán, Đã thanh toán, Quá hạn*).
  * Xem chi tiết từng khoản mục phí sinh hoạt, phí dịch vụ, phí gửi xe định kỳ.
  * Thanh toán trực tuyến an toàn và tức thì qua cổng **VNPAY** (ATM nội địa, QR Pay, Thẻ quốc tế).
  * Hóa đơn tự động cập nhật sang trạng thái **ĐÃ THANH TOÁN (PAID)** ngay khi xác thực thành công.
  * Hiển thị **Biên nhận thanh toán (Receipt)** chuẩn mobile-first, dễ dàng sao chép thông tin hoặc chụp màn hình đối soát.
* 📄 **Hợp đồng & Căn hộ**: Tra cứu hợp đồng thuê/sở hữu căn hộ, ngày hiệu lực, tiền cọc, và liên kết tệp tài liệu hợp đồng điện tử.
* 👨‍👩‍👧‍👦 **Thành viên Hộ gia đình**: Quản lý thông tin các nhân khẩu sinh sống tại căn hộ.
* 🛵 **Phương tiện & Thẻ gửi xe**: Đăng ký và theo dõi danh sách phương tiện (xe máy, ô tô, xe đạp) cùng trạng thái kích hoạt thẻ xe.
* 📦 **Yêu cầu Vận chuyển (Move In/Out)**: Đăng ký kế hoạch chuyển đồ ra/vào chung cư để Ban Quản Lý và An Ninh hỗ trợ thang máy.
* 🛠️ **Yêu cầu Bảo trì & Sửa chữa**: Gửi phản ánh sự cố cơ điện, nước, tiện ích kèm hình ảnh chụp thực tế và theo dõi tiến độ xử lý của kỹ thuật viên.
* ⚡ **Chỉ số Điện & Nước**: Tra cứu lượng tiêu thụ và lịch sử ghi nhận chỉ số tiện ích định kỳ.
* 🔔 **Thông báo Tòa nhà**: Nhận thông báo quan trọng từ Ban Quản Lý qua hệ thống thông báo đẩy **Firebase Cloud Messaging (FCM)**.

---

## 🛠️ Yêu Cầu Môi Trường (Prerequisites)

Trước khi cài đặt và chạy ứng dụng trên máy mới, hãy đảm bảo máy tính đã cài đặt:

1. **Flutter SDK**: Phiên bản `^3.13.1` hoặc mới hơn (Khuyến nghị Flutter `3.24.x` trở lên).
   * Kiểm tra bằng lệnh: `flutter --version`
2. **Dart SDK**: Đi kèm sẵn với Flutter SDK.
3. **Android Studio & Android SDK**:
   * Cài đặt Android SDK Platform, Android SDK Command-line Tools, và Android Emulator (hoặc sử dụng điện thoại Android thật có bật USB Debugging).
4. **Java Development Kit (JDK)**: JDK 17 (khuyến nghị tương thích Gradle mới nhất).
5. **Backend ASP.NET Core API**: Backend Apartment Management đang chạy tại cổng mặc định `5131`.

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng Trên Máy Khác

### Bước 1: Sao chép mã nguồn (Clone repository)

Mở Terminal / PowerShell và thực hiện:

```bash
git clone https://github.com/addd28/Apartment-management-App.git
cd Apartment-management-App
```

### Bước 2: Cài đặt các gói phụ thuộc (Dependencies)

Tải toàn bộ các thư viện cần thiết trong `pubspec.yaml`:

```bash
flutter pub get
```

### Bước 3: Cấu hình địa chỉ Backend API

Ứng dụng đã được tích hợp cơ chế nhận diện môi trường thông minh trong `lib/core/app_constants.dart`:

| Môi trường khởi chạy | Địa chỉ kết nối mặc định | Ghi chú |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:5131/api` | `10.0.2.2` trỏ trực tiếp về máy host chạy Backend |
| **Web Browser / Windows Desktop** | `http://localhost:5131/api` | Kết nối trực tiếp máy chủ cục bộ |
| **Điện thoại thật (Android / iOS)** | `http://<IP_LAN_CUA_MAY_HOST>:5131/api` | Điện thoại và máy tính cần kết nối chung một mạng Wi-Fi |

> 💡 **Mẹo**: Nếu chạy trên điện thoại thật, bạn có thể chỉnh sửa nhanh giá trị IP tại file `lib/core/app_constants.dart` hoặc thiết lập qua cài đặt trong ứng dụng.

### Bước 4: Kiểm tra thiết bị kết nối

Kiểm tra danh sách thiết bị đang sẵn sàng:

```bash
flutter devices
```

Ví dụ kết quả:
```text
Found 3 connected devices:
  sdk gphone16k x86 64 (mobile) • emulator-5554 • android-x64 • Android 17 (API 37) (emulator)
  Windows (desktop)             • windows       • windows-x64 • Microsoft Windows
  Chrome (web)                  • chrome        • web-javascript • Google Chrome
```

### Bước 5: Khởi chạy ứng dụng (Run App)

* **Chạy trên máy ảo Android (Khuyến nghị cho trải nghiệm di động)**:
  ```bash
  flutter run -d emulator-5554
  ```
  *(Thay `emulator-5554` bằng mã thiết bị của bạn từ lệnh `flutter devices`)*

* **Chạy trên máy tính Windows (Desktop)**:
  ```bash
  flutter run -d windows
  ```

* **Chạy trên trình duyệt Chrome (Web)**:
  ```bash
  flutter run -d chrome
  ```

---

## 🔑 Tài Khoản Đăng Nhập Thử Nghiệm

Dưới đây là tài khoản cư dân mẫu được khởi tạo sẵn trong hệ thống:

| Vai trò | Tên đăng nhập | Mật khẩu | Căn hộ phụ trách |
| :--- | :--- | :--- | :--- |
| **Cư dân (Resident)** | `resident` | `Password123!` | Phòng A101 (Tòa Sapphire) |

---

## 💳 Quy Trình Thanh Toán VNPAY Trực Tuyến

1. Đăng nhập với tài khoản cư dân.
2. Tại màn hình **Hóa Đơn & Tiền Phí**, chọn hóa đơn ở trạng thái **Chưa thanh toán**.
3. Bấm **Thanh toán**:
   * Màn hình hiển thị số tiền thanh toán rõ ràng.
   * Phương thức thanh toán chuẩn hóa duy nhất: **VNPAY - Thanh toán online**.
4. Bấm **Thanh toán** $\rightarrow$ Hệ thống gọi API backend sinh phiên giao dịch bảo mật và mở cổng thanh toán VNPAY trên trình duyệt.
5. Sau khi hoàn tất thanh toán trên VNPAY:
   * Hóa đơn tự động cập nhật sang trạng thái **✓ Đã thanh toán**.
   * Hệ thống hiển thị **Biên nhận thanh toán** với đầy đủ thông tin: *Mã hóa đơn, Căn hộ, Kỳ thanh toán, Số tiền, Mã giao dịch VNPAY, Thời gian xác nhận*.
   * Cư dân có thể xem lại biên nhận bất kỳ lúc nào từ danh sách hóa đơn.

---

## 📁 Cấu Trúc Thư Mục Dự Án

```text
lib/
├── core/
│   ├── api_client.dart          # Dio HTTP client, Interceptors, xử lý lỗi API
│   ├── app_constants.dart       # Cấu hình Base URL, màu sắc, phông chữ chủ đạo
│   └── storage_service.dart     # SharedPreferences quản lý JWT Token & User session
├── models/                      # DTOs & Data Models (Invoice, Payment, Contract, Vehicle,...)
├── screens/
│   ├── auth/                    # Màn hình đăng nhập & xác thực
│   ├── contracts/               # Danh sách và chi tiết hợp đồng căn hộ
│   ├── home/                    # Màn hình trang chủ & Dashboard cư dân
│   ├── household/               # Quản lý danh sách thành viên gia đình
│   ├── invoices/                # Quản lý hóa đơn, thanh toán VNPAY, lịch sử nộp tiền
│   ├── maintenance/             # Gửi phản ánh và theo dõi sửa chữa
│   ├── move_requests/           # Đăng ký lịch chuyển đồ ra/vào
│   ├── notifications/           # Danh sách thông báo tòa nhà
│   ├── profile/                 # Thông tin cá nhân cư dân
│   ├── utilities/               # Tra cứu chỉ số điện & nước
│   └── vehicles/                # Đăng ký thẻ xe & danh sách phương tiện
├── services/                    # Tầng giao tiếp Backend API (InvoiceService, VehicleService,...)
├── widgets/                     # UI components dùng chung (ReceiptDialog, CustomButton, StatusBadge,...)
└── main.dart                    # Điểm khởi chạy ứng dụng & Thiết lập Routing
```

---

## 🩺 Xử Lý Các Sự Cố Thường Gặp (Troubleshooting)

1. **Lỗi `Connection refused` hoặc không gọi được API**:
   * Kiểm tra xem Backend ASP.NET Core (`https://localhost:5131` hoặc `http://localhost:5131`) đã được khởi chạy chưa.
   * Nếu chạy trên máy ảo Android, hãy chắc chắn API client đang kết nối đến `http://10.0.2.2:5131/api`.
2. **Lỗi Gradle khi biên dịch lần đầu**:
   * Chạy lệnh dọn dẹp cache:
     ```bash
     flutter clean
     flutter pub get
     ```
   * Đảm bảo biến môi trường `JAVA_HOME` trỏ tới JDK 17 trở lên.
3. **Mở cổng thanh toán VNPAY không bật được trình duyệt**:
   * Ứng dụng đã tích hợp sẵn hộp thoại fallback cung cấp liên kết thanh toán trực tiếp để người dùng có thể nhấp mở trên bất kỳ trình duyệt nào.

---

## 🤝 Đóng Góp & Bản Quyền

Dự án thuộc quyền sở hữu của nhóm phát triển **Apartment Management App**. Mọi đóng góp xin vui lòng tạo Pull Request hoặc báo cáo Issue trực tiếp trên GitHub repository.
