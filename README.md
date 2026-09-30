# Motion Lab · Nhóm 05

Ứng dụng Flutter demo **cảm biến chuyển động, đếm bước chân và theo dõi phiên vận động**. Giao diện tiếng Việt, sử dụng `sensors_plus` và `pedometer`, được xây dựng tham khảo bốn tài liệu nhóm cung cấp.

## Chức năng

- **Tổng quan:** bắt đầu / tạm dừng / tiếp tục / kết thúc phiên; bước phiên, bộ đếm hệ thống, trạng thái đi bộ, mục tiêu, thời gian ghi, nhịp bước trung bình và quãng đường ước tính.
- **Cảm biến:** gia tốc kế, gia tốc tuyến tính, con quay hồi chuyển, từ kế; số X/Y/Z, độ lớn vector và đồ thị 120 mẫu gần nhất. Nhận diện lắc/xoay bằng ngưỡng minh họa.
- **Lịch sử:** lưu tối đa 50 phiên bằng `shared_preferences`; phân biệt đo thật/mô phỏng; sao chép kết quả CSV.
- **Kiến thức:** giải thích MEMS, nguyên lý nhận diện bước và vai trò của hai thư viện.
- **Mô phỏng:** đi bộ, đứng yên, lắc và xoay máy để thuyết trình khi không có phần cứng hỗ trợ. Có nhãn nguồn dữ liệu trên giao diện, lịch sử và CSV.
- **Thiết lập:** mục tiêu phiên 20–10.000 bước và độ dài một bước 0,30–1,20 m; giữ thiết lập sau khi mở lại.

## Chạy trên Android

Môi trường đã dùng: Flutter 3.47.5 / Dart 3.13.4, Android SDK. Dự án hiện chỉ cấu hình nền tảng Android.

```powershell
flutter pub get
flutter devices
flutter run -d <device-id>
```

Trên Android thật, chọn **Thiết bị thật** rồi **Cấp quyền / thử lại** nếu được nhắc. Quyền `ACTIVITY_RECOGNITION` đã khai báo trong manifest. Nếu đã chặn quyền, chọn **Mở Cài đặt**, cấp quyền Hoạt động thể chất, quay lại app và thử kết nối lại.

Để trình diễn không cần cảm biến: chọn **Mô phỏng** → **Đi bộ** → **Bắt đầu phiên**. Đợi mốc đầu tiên, quan sát số bước tăng; thử các trạng thái khác. Kết thúc phiên trước khi đổi nguồn dữ liệu.

## Đóng gói APK

```powershell
flutter build apk --debug
```

File: `build/app/outputs/flutter-apk/app-debug.apk`. Chép APK sang điện thoại để cài hoặc dùng:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Đây là bản debug phục vụ demo. Không cần máy chủ hoặc tài khoản. Dữ liệu lịch sử lưu cục bộ; sao chép CSV chỉ thực hiện khi nhấn nút.

`android/gradle.properties` tắt `kotlin.incremental` để tránh lỗi Kotlin cache khi thư viện Pub ở ổ C: còn dự án ở ổ D:. `pedometer 4.2.0` vẫn dùng Kotlin Gradle Plugin; Flutter hiện cảnh báo việc chuyển sang Built-in Kotlin trong tương lai.

## Cách tính và giới hạn

1. Mỗi đoạn đang ghi nhận sự kiện đầu tiên làm mốc. Các sự kiện tiếp theo cộng chênh lệch không âm. Bước trước mốc không được tính.
2. Tạm dừng ngừng đồng hồ và cộng bước. Tiếp tục lấy mốc mới để tránh đưa bước trong khoảng nghỉ vào phiên. Có thể bỏ sót những bước đầu đoạn do nền tảng cập nhật theo đợt.
3. Nếu giá trị mới thấp hơn sự kiện trước đó, giữ số đã ghi, lấy mốc mới và thông báo bộ đếm đặt lại.
4. Bước hệ thống không được gắn nhãn “bước hôm nay”. Lịch sử là các phiên đã kết thúc, không phải lịch sử hoạt động cả ngày.
5. Khi chưa có dữ liệu, hiển thị `—`; khi thiếu quyền/cảm biến, hiển thị lý do. Hai luồng số bước và trạng thái được xử lý lỗi độc lập.
6. Quãng đường = bước × độ dài bước / 1.000, đơn vị km. Nhịp bước = bước × 60 / số giây đang ghi; chỉ hiển thị sau 5 giây. Đây là giá trị trung bình/ước tính.
7. Cảm biến yêu cầu chu kỳ 50 ms (20 Hz); nhịp thực tế tùy thiết bị. Giao diện cập nhật khoảng 10 lần/giây. Biểu đồ có trục theo số mẫu, không giả định thời gian nhận mẫu luôn đều.
8. Lắc: độ lớn gia tốc tuyến tính > 12 m/s², giãn cách > 1 giây. Xoay: độ lớn vận tốc góc > 2,5 rad/s, giãn cách > 1,5 giây. Thao tác dài có thể kích hoạt nhiều lần. Hai phép phát hiện này **không cộng số bước**.
9. Demo chỉ theo dõi ở màn hình trước. Vào nền sẽ hủy stream và tự tạm dừng; quay lại phải nhấn Tiếp tục. Chưa triển khai dịch vụ nền, đồng bộ sức khỏe hoặc khôi phục phiên đang ghi khi tiến trình bị đóng.
10. Số đo thật cần kiểm chứng trên điện thoại. Mô phỏng không chứng minh độ chính xác của phần cứng hay thuật toán nền tảng.

## Cấu trúc mã nguồn

| File | Vai trò |
| --- | --- |
| `lib/main.dart` | Khởi tạo app, bốn màn hình, cài đặt và xuất CSV |
| `lib/motion_source.dart` | Quyền Android, stream hai plugin, nguồn mô phỏng, hủy đăng ký |
| `lib/motion_controller.dart` | Quản lý phiên, vòng đời, nhận diện thao tác, lịch sử và thiết lập |
| `lib/models.dart` | Vector, bộ đếm theo đoạn và bản ghi lịch sử |
| `lib/ui_components.dart` | Thành phần giao diện, vòng tiến độ và biểu đồ Canvas |
| `test/` | Kiểm thử bộ đếm, vòng đời, lỗi nguồn dữ liệu, lưu trữ và giao diện |
| `docs/DEMO.md` | Kịch bản thuyết trình và bảng kiểm thử trên máy thật |

## Kiểm tra

```powershell
flutter analyze
flutter test
```

Kiểm thử tự động bao gồm: mốc đầu tiên, cập nhật trùng, reset bộ đếm, tạm dừng/tiếp tục, vòng đời ứng dụng, thiếu quyền, thiếu luồng trạng thái, lưu nguồn mô phỏng và số chưa đo, độ dài bộ đệm, ngưỡng thao tác và luồng hoàn thành phiên trên màn hình 360 px.

Xem [kịch bản thuyết trình và bảng đo thực tế](docs/DEMO.md). Các phép thử trên phần cứng chưa có kết quả; không điền số mô phỏng vào báo cáo thực nghiệm.

Ảnh render giao diện bằng dữ liệu mô phỏng nằm trong `docs/previews/`. Trên Windows, có thể tạo lại bằng `flutter test tool/preview_test.dart` (dùng font Arial của Windows cho phần chữ trong ảnh xem trước).

## Tài liệu tham khảo

Bốn tài liệu đã đọc: `số 1.docx`, `Cong_nghe_MEMS_va_nguyen_ly_dem_buoc.docx`, `Pedometer_Noi_dung_thuyet_trinh.docx`, `TaiLieu_SensorsPlus_Flutter.docx`.

- [sensors_plus: API cảm biến và yêu cầu nền tảng](https://pub.dev/packages/sensors_plus)
- [pedometer: bộ đếm bước và trạng thái](https://pub.dev/packages/pedometer)
- [permission_handler: quyền ứng dụng](https://pub.dev/packages/permission_handler)
- [shared_preferences: lưu dữ liệu cục bộ](https://pub.dev/packages/shared_preferences)
- [Android Motion sensors](https://developer.android.com/develop/sensors-and-location/sensors/sensors_motion)
