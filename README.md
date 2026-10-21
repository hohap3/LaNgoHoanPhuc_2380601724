================================================================================

&#x20;         BÁO CÁO TỔNG HỢP CÁC CHỨC NĂNG ĐÃ THỰC HIỆN TRONG DỰ ÁN

&#x20;         ỨNG DỤNG FLUTTER MOBILE - PHÂN QUYỀN \& TIỆN ÍCH NÂNG CAO

================================================================================

Nền tảng            : Flutter (Android / Multi-platform)

Ngôn ngữ            : Dart (SDK ^3.13.3)

Phiên bản           : 1.0.0+1

================================================================================



I. TỔNG QUAN HỆ THỐNG

\--------------------------------------------------------------------------------

Dự án là ứng dụng di động hoàn chỉnh bao gồm hệ thống Xác thực bảo mật 2 lớp (2FA),

Phân quyền theo vai trò (Role-Based Access Control: Admin, Staff, Customer),

Quản trị dữ liệu người dùng (CRUD Users), kết hợp chuỗi tính năng phần cứng thiết

bị di động cao cấp: Định vị GPS \& Chia sẻ vị trí, Sinh trắc học (Vân tay/FaceID),

Quét \& Tạo mã QR/Barcode, Giao tiếp không tiếp xúc NFC, và Dịch thuật đa ngôn ngữ.





II. CHI TIẾT CÁC TÍNH NĂNG ĐÃ HOÀN THIỆN

\--------------------------------------------------------------------------------



1\. HỆ THỐNG XÁC THỰC \& BẢO MẬT (AUTHENTICATION \& SECURITY)

&#x20;  - Đăng ký tài khoản (Register):

&#x20;    + Nhập đầy đủ thông tin: Họ tên, Tên đăng nhập, Email, Số điện thoại, Mật khẩu.

&#x20;    + Kiểm tra hợp lệ dữ liệu (Validate form: định dạng email, độ dài mật khẩu, trùng khớp mật khẩu).

&#x20;    + Phân bổ vai trò mặc định hoặc tùy chọn khi tạo tài khoản.

&#x20;  - Đăng nhập (Login):

&#x20;    + Đăng nhập bằng Tên đăng nhập và Mật khẩu.

&#x20;    + Nhớ thông tin đăng nhập và hỗ trợ cấu hình chuyển nhanh.

&#x20;  - Xác thực bảo mật 2 lớp (2FA - OTP Verification):

&#x20;    + Sau khi nhập đúng mật khẩu, hệ thống gửi mã OTP xác thực 6 số qua Email.

&#x20;    + Giao diện nhập mã OTP chuyên nghiệp dạng ô từng ký tự tự động focus.

&#x20;    + Bộ đếm ngược thời gian hết hạn OTP (60 giây).

&#x20;    + Chức năng gửi lại mã OTP (Resend OTP) khi hết thời gian.

&#x20;  - Quản lý phiên làm việc \& Token:

&#x20;    + Lưu trữ an toàn Bearer Token và Refresh Token qua SharedPreferences.

&#x20;    + Tự động đính kèm Token xác thực vào Header của mọi API yêu cầu bảo mật.

&#x20;    + Tự động phân luồng điều hướng màn hình đúng theo vai trò (Role) sau khi xác thực thành công.

&#x20;    + Chức năng Đăng xuất an toàn: Xóa session, xóa token và điều hướng về trang đăng nhập.



2\. PHÂN QUYỀN \& GIAO DIỆN THEO VAI TRÒ (ROLE-BASED ACCESS CONTROL - RBAC)

&#x20;  Hệ thống tự động nhận diện danh sách quyền của tài khoản để đưa vào giao diện tương ứng:

&#x20;  

&#x20;  A. DÀNH CHO QUẢN TRỊ VIÊN (ADMIN DASHBOARD):

&#x20;     - Quản lý danh sách người dùng toàn diện (CRUD):

&#x20;       + Xem danh sách tất cả tài khoản trong hệ thống kèm trạng thái và vai trò.

&#x20;       + Tìm kiếm người dùng tức thì theo Tên đăng nhập, Email, Họ tên hoặc Số điện thoại.

&#x20;       + Bộ lọc danh sách theo vai trò (Tất cả, Admin, Staff, Customer).

&#x20;       + Thao tác Kéo để làm mới (Pull-to-Refresh) danh sách từ máy chủ.

&#x20;     - Xem chi tiết thông tin người dùng:

&#x20;       + Hộp thoại hiển thị đầy đủ: ID, Username, Email, Số điện thoại, Vai trò, Ngày tạo tài khoản, Trạng thái kích hoạt.

&#x20;     - Thêm người dùng mới (Create):

&#x20;       + Form tạo tài khoản trực tiếp từ giao diện Admin, gán quyền linh hoạt.

&#x20;     - Cập nhật thông tin người dùng (Update):

&#x20;       + Chỉnh sửa Email, Số điện thoại, Họ tên, thay đổi vai trò (Roles), Khóa / Mở khóa tài khoản.

&#x20;     - Xóa người dùng (Delete):

&#x20;       + Hộp thoại cảnh báo xác nhận trước khi xóa tài khoản khỏi hệ thống.



&#x20;  B. DÀNH CHO NHÂN VIÊN (STAFF DASHBOARD):

&#x20;     - Giao diện làm việc chuyên biệt dành cho nhân sự tác nghiệp.

&#x20;     - Quản lý và theo dõi danh sách nhiệm vụ / công việc theo ca làm việc.

&#x20;     - Hiển thị mức độ ưu tiên (Khẩn cấp, Cao, Trung bình, Bình thường) và tiến độ xử lý.

&#x20;     - Truy cập nhanh vào các công cụ tiện ích mở rộng (GPS, QR, NFC, Dịch thuật).



&#x20;  C. DÀNH CHO KHÁCH HÀNG (CUSTOMER DASHBOARD):

&#x20;     - Giao diện trải nghiệm người dùng hiện đại, thân thiện.

&#x20;     - Quản lý các danh mục: Đơn hàng của tôi, Ưu đãi \& Voucher, Ví \& Thanh toán, Trung tâm hỗ trợ.

&#x20;     - Tích hợp lối tắt truy cập các tính năng công nghệ thông minh.



3\. TÍNH NĂNG PHẦN CỨNG 1: ĐỊNH VỊ GPS \& CHIA SẺ VỊ TRÍ (LOCATION SHARING)

&#x20;  - Tự động kiểm tra dịch vụ GPS và xin cấp quyền truy cập vị trí (Location Permissions).

&#x20;  - Lấy tọa độ địa lý chính xác cao hiện tại (Vĩ độ - Latitude, Kinh độ - Longitude).

&#x20;  - Hiển thị đầy đủ thông số định vị: Độ chính xác (Accuracy theo mét), Độ cao (Altitude), Tốc độ di chuyển (Speed).

&#x20;  - Chế độ Theo dõi trực tiếp (Live Tracking Mode):

&#x20;    + Lắng nghe Stream tọa độ GPS liên tục cập nhật theo thời gian thực khi người dùng di chuyển.

&#x20;  - Tạo liên kết Google Maps tự động (`https://maps.google.com/?q=lat,lng`).

&#x20;  - Sao chép nhanh tọa độ hoặc đường link bản đồ vào Clipboard.

&#x20;  - Chia sẻ vị trí tức thì (Share Location):

&#x20;    + Tích hợp thư viện Share Plus giúp chia sẻ trực tiếp tọa độ và link Google Maps qua Zalo, Messenger, Tin nhắn SMS, Email,... chỉ với 1 chạm.



4\. TÍNH NĂNG PHẦN CỨNG 2: SINH TRẮC HỌC (BIOMETRIC AUTHENTICATION)

&#x20;  - Kiểm tra tính tương thích phần cứng của thiết bị (Hỗ trợ cảm biến vân tay Fingerprint, nhận diện gương mặt FaceID).

&#x20;  - Liệt kê danh sách các phương thức sinh trắc học thiết bị hỗ trợ.

&#x20;  - Thực hiện quét vân tay / FaceID an toàn thông qua nền tảng bảo mật của hệ điều hành (LocalAuthentication).

&#x20;  - Hỗ trợ lưu trữ cấu hình cho phép Đăng nhập nhanh bằng vân tay vào các lần sau mà không cần nhập lại mật khẩu.



5\. TÍNH NĂNG PHẦN CỨNG 3: MÃ QR \& MÃ VẠCH (QR CODE \& BARCODE)

&#x20;  - Quét mã qua Camera thời gian thực (Live Scanner):

&#x20;    + Tích hợp thư viện `mobile\_scanner` quét cực nhanh và chính xác cả mã QR 2D và mã vạch Barcode 1D.

&#x20;    + Hỗ trợ nút bật/tắt Đèn Flash trợ sáng khi quét trong môi trường tối.

&#x20;    + Hỗ trợ chuyển đổi Camera trước / sau linh hoạt.

&#x20;    + Hiệu ứng khung ngắm quét laser chuyển động chuyên nghiệp.

&#x20;  - Quét mã từ hình ảnh trong Thư viện ảnh (Gallery Scanner):

&#x20;    + Chọn ảnh chụp sẵn chứa mã QR / Barcode từ album để giải mã dữ liệu.

&#x20;  - Trình tạo \& hiển thị mã (Generator):

&#x20;    + Nhập văn bản bất kỳ để trực quan hóa thành mã QR Code hoặc mã vạch Barcode 1D (Code 128).

&#x20;    + Hỗ trợ sao chép nội dung quét, chia sẻ kết quả trực tiếp.



6\. TÍNH NĂNG PHẦN CỨNG 4: GIAO TIẾP TẦM NGẮN NFC (NEAR FIELD COMMUNICATION)

&#x20;  - Mô phỏng và tích hợp đọc thẻ thông minh NFC:

&#x20;    + Thẻ Sinh viên / Thẻ Nhân viên (HUTECH ID Card).

&#x20;    + Căn cước công dân gắn chip (CCCD Chuẩn ICAO).

&#x20;    + Thẻ thanh toán không tiếp xúc (EMV Contactless Visa/Mastercard).

&#x20;    + Thẻ thông minh NDEF (NTAG215).

&#x20;  - Hiển thị chi tiết dữ liệu thẻ: Mã định danh UID, Chuẩn công nghệ (ISO/IEC 14443 Type A/B), Dung lượng bộ nhớ, Dữ liệu Payload NDEF.

&#x20;  - Hỗ trợ tính năng ghi dữ liệu vào thẻ NFC (NFC Tag Writer).



7\. TÍNH NĂNG 5: DỊCH THUẬT ĐA NGÔN NGỮ (MULTILINGUAL TRANSLATION)

&#x20;  - Dịch thuật văn bản thời gian thực (Realtime Text Translation):

&#x20;    + Kết nối dịch trực tiếp thông qua Google Translate API tốc độ cao.

&#x20;    + Hỗ trợ hơn 10 ngôn ngữ phổ biến: Tiếng Việt, Tiếng Anh, Tiếng Nhật, Tiếng Hàn, Tiếng Trung, Tiếng Pháp, Tiếng Đức, Tiếng Tây Ban Nha, Tiếng Nga, Tiếng Thái.

&#x20;    + Tính năng Tự động phát hiện ngôn ngữ nguồn (Auto-detect language).

&#x20;  - Tiện ích dịch thông minh:

&#x20;    + Nút chuyển đổi nhanh chiều dịch (Swap languages).

&#x20;    + Xóa nhanh văn bản, sao chép kết quả dịch 1 chạm.

&#x20;  - Dịch từ hình ảnh (Image Translation):

&#x20;    + Chụp ảnh trực tiếp từ Camera hoặc chọn ảnh từ Thư viện (ImagePicker) để hỗ trợ dịch nội dung.



8\. CẤU HÌNH MẠNG \& KẾT NỐI API ĐỘNG (DYNAMIC API CONFIGURATION)

&#x20;  - Hộp thoại Cấu hình Máy chủ (API Settings Dialog):

&#x20;    + Cho phép đổi URL API Backend ngay trên ứng dụng mà không cần build lại mã nguồn.

&#x20;    + Cài đặt sẵn các cấu hình nhanh (Presets):

&#x20;      \* Android Emulator (`http://10.0.2.2:5000/api`)

&#x20;      \* Localhost máy tính (`http://localhost:5000/api`)

&#x20;      \* Mạng LAN WiFi nội bộ (VD: `http://192.168.1.x:5000/api`)

&#x20;    + Kiểm tra trạng thái kết nối mạng (Ping / Connection test).

&#x20;    + Lưu cấu hình máy chủ vào SharedPreferences để ghi nhớ cho các phiên sau.





III. CẤU TRÚC KIẾN TRÚC MÃ NGUỒN (PROJECT ARCHITECTURE)

\--------------------------------------------------------------------------------

lib/

&#x20;├── main.dart                                # Điểm khởi chạy ứng dụng \& Thiết lập Theme

&#x20;├── config/

&#x20;│    └── app\_config.dart                     # Quản lý cấu hình API URL, Bảng màu sắc chuẩn

&#x20;├── models/

&#x20;│    ├── api\_response.dart                   # Mô hình phản hồi chuẩn hóa từ API Backend

&#x20;│    └── user\_model.dart                     # Model User, Request đăng ký, đăng nhập, cập nhật

&#x20;├── services/

&#x20;│    ├── api\_service.dart                    # Xử lý toàn bộ HTTP Request (Auth, 2FA, CRUD Users)

&#x20;│    ├── storage\_service.dart                # Quản lý SharedPreferences (Token, Role, Settings)

&#x20;│    └── translation\_service.dart            # Service kết nối Google Translate API

&#x20;├── screens/

&#x20;│    ├── splash\_screen.dart                  # Màn hình chờ kiểm tra phiên đăng nhập

&#x20;│    ├── auth/

&#x20;│    │    ├── login\_screen.dart              # Màn hình đăng nhập

&#x20;│    │    ├── register\_screen.dart           # Màn hình đăng ký tài khoản

&#x20;│    │    └── verify\_otp\_screen.dart         # Màn hình xác thực mã OTP 2FA

&#x20;│    ├── admin/

&#x20;│    │    ├── admin\_dashboard\_screen.dart    # Bảng điều khiển Quản trị viên \& Danh sách người dùng

&#x20;│    │    ├── user\_detail\_dialog.dart        # Hộp thoại xem thông tin chi tiết người dùng

&#x20;│    │    ├── user\_edit\_dialog.dart          # Hộp thoại chỉnh sửa thông tin \& vai trò

&#x20;│    │    └── user\_form\_dialog.dart          # Hộp thoại tạo mới người dùng

&#x20;│    ├── staff/

&#x20;│    │    └── staff\_dashboard\_screen.dart    # Bảng điều khiển Nhân viên tác nghiệp

&#x20;│    ├── customer/

&#x20;│    │    └── customer\_dashboard\_screen.dart # Bảng điều khiển Khách hàng

&#x20;│    └── features/

&#x20;│         ├── biometric\_nfc\_qr\_screen.dart   # Màn hình tích hợp Sinh trắc học, QR/Barcode và NFC

&#x20;│         ├── qr\_barcode\_scanner\_screen.dart # Màn hình quét Camera QR / Barcode chuyên dụng

&#x20;│         ├── location\_sharing\_screen.dart   # Màn hình định vị GPS \& Chia sẻ vị trí

&#x20;│         └── translation\_screen.dart        # Màn hình dịch thuật đa ngôn ngữ thời gian thực

&#x20;└── widgets/

&#x20;     ├── api\_settings\_dialog.dart            # Hộp thoại đổi API Endpoint linh hoạt

&#x20;     ├── app\_dialogs.dart                    # Hộp thoại thông báo Success, Error, Loading

&#x20;     ├── custom\_button.dart                  # Nút bấm tùy biến giao diện hiện đại

&#x20;     ├── custom\_text\_field.dart              # Ô nhập liệu có validation \& icon

&#x20;     ├── features\_grid\_section.dart          # Widget hiển thị phím tắt tính năng mở rộng

&#x20;     └── role\_badge.dart                     # Badge phân loại vai trò trực quan theo màu





IV. DANH SÁCH CÁC THƯ VIỆN CHÍNH ĐÃ TÍCH HỢP (DEPENDENCIES)

\--------------------------------------------------------------------------------

\- flutter / sdk: Xây dựng giao diện Material 3.

\- http (^1.6.0): Kết nối giao thức RESTful API, gửi nhận dữ liệu JSON.

\- shared\_preferences (^2.5.6): Lưu trữ cục bộ Token, Session, Cấu hình API.

\- geolocator (^14.1.2): Định vị toàn cầu GPS, lấy tọa độ, Stream vị trí realtime.

\- share\_plus (^13.3.1): Chia sẻ dữ liệu, tọa độ, bản đồ sang các app khác.

\- local\_auth (^3.0.2): Xác thực sinh trắc học vân tay, FaceID.

\- mobile\_scanner (^7.4.2): Quét mã QR Code và Barcode qua Camera phần cứng.

\- image\_picker (^1.2.4): Chọn ảnh từ Thư viện và Chụp ảnh từ Camera.

\- cupertino\_icons (^1.0.8): Hệ thống icon giao diện.





V. KẾT LUẬN \& ĐÁNH GIÁ

\--------------------------------------------------------------------------------

\- Ứng dụng hoạt động mượt mà, đầy đủ tính năng theo yêu cầu bài kiểm tra

\- Đảm bảo tính toàn vẹn dữ liệu, kiểm soát ngoại lệ (Exception Handling, Timeout, Lỗi mạng).

\- Giao diện Material 3 đẹp mắt, chuẩn UX/UI với màu sắc hài hòa và phản hồi tương tác tốt.

\- Đáp ứng đầy đủ quy trình xác thực đa lớp bảo mật kết hợp khai thác hiệu quả các phần cứng

&#x20; di động hiện đại (Camera, GPS, Biometric, NFC).

================================================================================



