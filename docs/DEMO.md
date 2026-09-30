# Kịch bản thuyết trình Motion Lab — Nhóm 05

## Chuẩn bị

- Android thật có cảm biến bước: cài APK, mở app và cấp quyền Hoạt động thể chất qua nút **Cấp quyền / thử lại**.
- Chọn mục tiêu **30 bước** trong biểu tượng cài đặt ở góc trên.
- Nếu thiết bị không hỗ trợ, chọn **Mô phỏng** trước khi bắt đầu. Luôn nói rõ đây là dữ liệu tổng hợp.
- Để màn hình bật và ứng dụng ở phía trước. Ra màn hình chính sẽ tự tạm dừng phiên.

## Trình diễn khoảng 3–5 phút

### 1. Tín hiệu cảm biến

Mở **Cảm biến** → **Gia tốc kế**, đặt máy nằm yên. Giải thích độ lớn thường gần 9,81 m/s² do trọng lực; trục nào có giá trị lớn phụ thuộc tư thế máy.

Chuyển **Gia tốc tuyến tính**: các giá trị thường gần 0 khi máy đứng yên. Cầm máy lắc nhẹ, quan sát đồ thị và số lần phát hiện. Chọn **Con quay hồi chuyển**, xoay máy để quan sát tốc độ góc. **Từ kế** thể hiện từ trường, không phải tốc độ di chuyển.

Lời dẫn: “sensors_plus cung cấp các luồng dữ liệu. Nhóm tự tính độ lớn và đặt ngưỡng để minh họa thao tác lắc/xoay.”

### 2. Phiên đếm bước

Mở **Tổng quan** → **Bắt đầu phiên**. Nếu cảm biến chưa gửi sự kiện đầu tiên, đi vài bước để kích hoạt và chờ thông báo **Đã nhận mốc bước**. Sau đó mới đếm thủ công 30 bước. Khi dừng lại, chờ bộ đếm cập nhật rồi nhấn **Kết thúc**.

Giải thích: “pedometer trả về bộ đếm nền tảng. Nhóm lấy chênh lệch giữa các sự kiện của phiên, không coi số hệ thống là tổng bước hôm nay.”

Trạng thái walking/stopped là luồng độc lập. Nếu không khả dụng, vẫn có thể nhận số bước. Trạng thái có thể trễ.

### 3. Tạm dừng và mục tiêu

Thử **Tạm dừng**, đi vài bước, **Tiếp tục**. Ứng dụng lấy sự kiện đầu tiên sau tiếp tục làm mốc mới để bỏ qua khoảng tạm dừng. Vì dữ liệu có thể cập nhật theo đợt, một số bước đầu đoạn không được tính. Đồng hồ chỉ tính thời gian đang ghi.

Quãng đường là ước tính: số bước × độ dài một bước; mặc định 0,70 m. Nhịp bước là trung bình trên thời gian ghi, chưa hiển thị trong 5 giây đầu.

### 4. Lưu kết quả

Nhấn **Kết thúc** → **Lịch sử**. Lọc **Đo thật** hoặc **Mô phỏng**. Có thể **Sao chép CSV** để dán vào bảng tính. Lịch sử giữ 50 phiên gần nhất và còn sau khi mở lại app.

### 5. Giải thích nguyên lý

Mở **Kiến thức**. Liên hệ MEMS → tín hiệu số → lọc → tìm đỉnh → điều kiện thời gian → nhận diện bước. Thuật toán tìm đỉnh là nguyên lý giảng giải; ứng dụng không khẳng định đó là thuật toán nội bộ của pedometer.

## Khi dùng mô phỏng

| Nút | Hành vi |
| --- | --- |
| Đi bộ | Tạo tín hiệu tuần hoàn và 2 bước/giây |
| Đứng yên | Gia tốc tổng có trọng lực, gia tốc tuyến tính gần 0, bước không tăng |
| Lắc máy | Gia tốc tuyến tính lớn, tăng số lần phát hiện lắc; bước không tăng |
| Xoay máy | Vận tốc góc tăng, tăng số lần phát hiện xoay; bước không tăng |

Số mô phỏng chỉ dùng kiểm tra luồng ứng dụng và thuyết trình, không đánh giá độ chính xác cảm biến.

## Bảng kiểm thử trên điện thoại thật

Chưa có thiết bị Android kết nối trong môi trường phát triển; các ô dưới đây cần nhóm tự đo.

| Bài thử | Kết quả mong đợi | Kết quả thực tế |
| --- | --- | --- |
| Từ chối quyền vận động | Hiển thị thiếu quyền, số bước chưa có dữ liệu | Chưa kiểm thử |
| Chặn quyền rồi mở Cài đặt | Có hướng dẫn cấp lại quyền | Chưa kiểm thử |
| Để máy yên | Gia tốc tổng gần 9,81; tuyến tính gần 0 | Chưa kiểm thử |
| Đi chậm 30 bước, bỏ túi | Ghi số bước sau mốc và độ trễ cập nhật | Chưa kiểm thử |
| Đi bình thường 30 bước, cầm tay | So sánh với số đếm thủ công | Chưa kiểm thử |
| Lắc nhẹ khi đứng yên | Thử nhận lắc; kiểm tra có bước hệ thống nhận nhầm không | Chưa kiểm thử |
| Tạm dừng, đi tiếp, tiếp tục | Không cộng khoảng tạm dừng | Chưa kiểm thử |
| Ra màn hình chính rồi quay lại | Phiên tự tạm dừng, phải nhấn Tiếp tục | Chưa kiểm thử |
| Kết thúc, đóng và mở lại | Phiên đã kết thúc còn trong lịch sử | Chưa kiểm thử |
| Máy thiếu step counter/status | Thông báo riêng cho luồng không khả dụng | Chưa kiểm thử |

Với mỗi lần thử, ghi model máy, phiên bản Android, vị trí máy, số bước thủ công, số bước app, thời gian chờ. Không dùng kết quả mô phỏng thay cho kết quả thực nghiệm.
