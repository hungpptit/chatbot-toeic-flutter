**CẤU TRÚC SLIDE CHO BÀI THUYẾT TRÌNH**

**1\. Slide Mở Đầu (1 Slide)**

- Tên đề tài (Ví dụ: Hệ thống đặt vé phim hướng dịch vụ, Hệ thống E-commerce bán hàng...).
- Tên môn học, tên giảng viên hướng dẫn.
- Danh sách thành viên nhóm và bảng phân chia tỷ lệ đóng góp / vai trò công việc của từng thành viên (để giảng viên dễ vấn đáp và chấm điểm công bằng).

**2\. Phát Biểu Bài Toán & Nhu Cầu Hướng Dịch Vụ (1-2 Slides)**

- Bối cảnh & Bài toán: Nêu ngắn gọn hệ thống này giải quyết vấn đề gì thực tế (Business Requirements).
- Lý do chọn SOA/Microservices: Tại sao hệ thống này cần làm theo hướng dịch vụ? (Ví dụ: Để dễ mở rộng, tách biệt các module độc lập như quản lý người dùng, quản lý rạp, xử lý thanh toán...).

**3\. Kiến Trúc Hệ Thống - SOA/Microservices Architecture (3-5 Slides )**

- Sơ đồ kiến trúc tổng thể (Architecture Diagram): Vẽ rõ luồng đi từ Client -> API Gateway -> Các dịch vụ độc lập (Services).
- Danh sách các Dịch vụ (Services Definition): Liệt kê rõ hệ thống gồm những dịch vụ nào (Ví dụ: Customer Service, Movie/Theater Service, Booking Service, Payment Service).
- Cơ sở dữ liệu (Database per Service): Chỉ rõ các dịch vụ quản lý dữ liệu độc lập như thế nào (đặc trưng của hướng dịch vụ) để bảo đảm lỏng lẻo về mặt liên kết (Loose coupling).

**4\. Giải Pháp Tích Hợp & Giao Tiếp Giữa Các Dịch Vụ (2-3 Slides)**

- Phương thức giao tiếp: Nhóm dùng phương thức nào?
- Giao tiếp đồng bộ (Synchronous): HTTP/REST API, gRPC.
- Giao tiếp bất đồng bộ (Asynchronous): Sử dụng Message Broker (RabbitMQ, Kafka) cho các tác vụ như gửi email, xử lý hàng đợi đặt vé.
- Tích hợp bên thứ ba (Third-party Integration): Nếu có tích hợp cổng thanh toán (ví dụ: VNPay API) hoặc dịch vụ gửi SMS/Email, hãy show rõ sơ đồ luồng tích hợp này.

**5\. Demo Sản Phẩm Thực Tế ( 5-10 phút)**

- Thự hiện đề mono đề tài.
- Yêu cầu demo: Chỉ tập trung vào luồng nghiệp vụ chính, quan trọng nhất thể hiện sự tương tác giữa các dịch vụ.

**6\. Kết Luận & Hướng Phát Triển (1-2 Slide)**

- Những gì nhóm đã làm được và công nghệ sử dụng (Ví dụ: ASP.NET Core, Docker, SQL Server...).
- Hạn chế hiện tại và hướng tối ưu (Ví dụ: Triển khai CI/CD, áp dụng môt số giải pháp bảo mật cho API Gateway).