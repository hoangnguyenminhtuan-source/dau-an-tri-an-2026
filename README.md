# DẤU ẤN TRI ÂN – 20/11/2026
Website MVP cho Đoàn trường Cao đẳng Đắk Lắk.

## 1. Thành phần
- `index.html`: toàn bộ giao diện và mã JavaScript phía trình duyệt (một file ứng dụng).
- `supabase-setup.sql`: tạo bảng, phân quyền RLS và Storage.
- `vercel.json`: cấu hình triển khai static site.
- `README.md`: hướng dẫn thiết lập và triển khai.

Đây là dự án website tĩnh kết nối Supabase. ZIP giúp gom toàn bộ dự án thành một tệp để tải lên GitHub; không phải một file HTML độc lập có thể tự lưu tài khoản và dữ liệu mà không cần backend.

## 2. Tạo Supabase
1. Tạo project tại https://supabase.com/.
2. Mở **SQL Editor**, dán toàn bộ nội dung `supabase-setup.sql` và chạy.
3. Vào **Project Settings → API** (hoặc Data API), sao chép:
   - Project URL
   - anon/public key
4. Mở `index.html`, tìm hai dòng:
   ```js
   const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";
   const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
   ```
   Thay bằng thông tin project của bạn. Chỉ dùng `anon`/`publishable` key ở trình duyệt. **Tuyệt đối không đưa service_role key vào mã nguồn hoặc GitHub.**

## 3. Tạo tài khoản quản trị
1. Mở website sau khi đã cấu hình Supabase.
2. Đăng ký tài khoản bằng email của Ban tổ chức.
3. Mở email và xác minh tài khoản.
4. Trong Supabase → SQL Editor, chạy lệnh sau, thay email:
   ```sql
   update public.profiles p
   set role = 'admin'
   from auth.users u
   where p.id = u.id
     and u.email = 'EMAIL_QUAN_TRI_CUA_BAN';
   ```
5. Đăng xuất rồi đăng nhập lại để tải quyền quản trị.

## 4. Đưa lên GitHub và Vercel
1. Giải nén ZIP.
2. Tạo repository GitHub mới và tải lên `index.html`, `supabase-setup.sql`, `README.md`, `vercel.json`.
3. Đăng nhập https://vercel.com/ → **Add New → Project** → Import repository.
4. Framework Preset: **Other**; Build Command để trống; Output Directory để trống hoặc `.`; Deploy.
5. Vercel sẽ cấp địa chỉ HTTPS. Có thể gắn tên miền riêng sau.

## 5. Cách sử dụng
- Sinh viên đăng ký, xác minh email, đăng nhập và gửi lời chúc/ảnh/video/link.
- Nội dung mới luôn ở trạng thái `PENDING`.
- Quản trị mở **Quản trị → Chờ duyệt**, chọn Duyệt hoặc Từ chối.
- Chỉ bài `APPROVED` mới hiển thị trên khu vực công khai.
- Ở mục Đã duyệt, chọn **Chọn trình chiếu** để đưa nội dung vào màn hình trình chiếu.
- Mục Thống kê tổng hợp số bài gửi theo khoa, chi đoàn và hoạt động; có nút xuất CSV.

## 6. Lưu ý quan trọng trước khi công khai
- Form hiện tại cho phép sinh viên nhập khoa/lớp/chi đoàn dạng văn bản. Để tránh tên đơn vị bị nhập không thống nhất, Ban tổ chức nên chuẩn hóa danh mục và cập nhật form thành danh sách chọn trước khi phát động chính thức.
- Mỗi mã sinh viên là duy nhất trong cơ sở dữ liệu. Nếu mã đã được đăng ký, đăng ký trùng sẽ bị từ chối.
- Supabase Auth có thể yêu cầu cấu hình URL redirect: vào **Authentication → URL Configuration**, đặt Site URL là domain Vercel và thêm domain preview cần dùng vào Redirect URLs.
- Video được tải lên Storage công khai theo URL. Chỉ tải lên nội dung mà người gửi có quyền sử dụng và đã đồng ý công khai. Ban tổ chức cần kiểm duyệt trước khi duyệt bài.
- Link TikTok chỉ được lưu dưới dạng liên kết ngoài; trình duyệt không đảm bảo nhúng/phát mọi video TikTok.
- Giới hạn upload mặc định trong mã là 50 MB. Cần kiểm tra giới hạn Storage và băng thông theo gói Supabase đang sử dụng.
- Khi tổ chức sự kiện, nên tải riêng ảnh/video đã duyệt về máy tính trình chiếu và kiểm tra trước tại hội trường. Phiên bản MVP này chưa có chức năng đóng gói media offline tự động.
- Không nhập dữ liệu cá nhân nhạy cảm. Công khai tên hiển thị và nội dung sau khi có sự đồng ý phù hợp.
- Nên thử nghiệm bằng tài khoản sinh viên và tài khoản quản trị trước khi chia sẻ rộng rãi.

## 7. Giới hạn phiên bản MVP
Đây là bản khởi tạo chạy được cho quy trình cơ bản, chưa phải hệ thống đã kiểm thử tải lớn hoặc kiểm định an toàn chuyên sâu. Trước khi vận hành chính thức, cần kiểm tra chính sách RLS, email xác minh, quy trình xử lý nội dung vi phạm và phương án sao lưu dữ liệu.
