import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def send_update_email():
    smtp_user = 'shiinamizuha@gmail.com'
    smtp_pass = 'sqrb gpxw zutb ukdq'
    admin_email = 'ngovanm691@gmail.com'
    reporter_email = 'phuczx210@gmail.com'
    version = 'v1.1.4'

    recipients = [reporter_email, admin_email]

    subject = f"⚡ [TIÊN LỘ {version}] Thông Báo Khắc Phục Hoàn Toàn Sự Cố & Cập Nhật Tính Năng Mới"

    html_content = f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #070d18; color: #e2e8f0; margin: 0; padding: 24px; }}
    .card {{ background-color: #0f172a; border: 1px solid #334155; border-radius: 16px; max-width: 680px; margin: 0 auto; overflow: hidden; box-shadow: 0 12px 35px rgba(0,0,0,0.65); }}
    .header {{ background: linear-gradient(135deg, #0f766e 0%, #047857 50%, #064e3b 100%); padding: 26px; border-bottom: 2px solid #10b981; text-align: center; }}
    .header h1 {{ margin: 0; font-size: 22px; color: #ffffff; letter-spacing: 0.5px; }}
    .badge {{ display: inline-block; padding: 6px 16px; border-radius: 20px; font-size: 12px; font-weight: 800; background-color: #f59e0b; color: #0f172a; text-transform: uppercase; margin-top: 10px; letter-spacing: 0.5px; }}
    .content {{ padding: 28px; }}
    .greeting {{ font-size: 15.5px; color: #f8fafc; line-height: 1.65; margin-bottom: 22px; }}
    .box {{ background-color: #1e293b; border: 1px solid #334155; border-radius: 14px; padding: 20px; margin-bottom: 22px; }}
    .box-title {{ font-size: 13.5px; font-weight: 800; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 14px; display: flex; align-items: center; gap: 8px; }}
    .issue-item {{ margin-bottom: 14px; line-height: 1.6; font-size: 14px; }}
    .issue-title {{ font-weight: 700; color: #fde68a; display: block; margin-bottom: 4px; }}
    .issue-desc {{ color: #cbd5e1; font-size: 13.5px; line-height: 1.5; }}
    .download-btn {{ display: inline-block; background: linear-gradient(135deg, #eab308 0%, #ca8a04 100%); color: #0f172a; font-weight: 800; font-size: 15px; text-decoration: none; padding: 14px 28px; border-radius: 12px; margin: 10px 0; text-align: center; box-shadow: 0 4px 15px rgba(234, 179, 8, 0.4); }}
    .footer {{ padding: 18px 24px; background-color: #070d18; border-top: 1px solid #1e293b; text-align: center; font-size: 12px; color: #94a3b8; line-height: 1.5; }}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>⚡ [TIÊN LỘ] THÔNG BÁO HOÀN TẤT KHẮC PHỤC SỰ CỐ</h1>
      <div class="badge">BẢN CẬP NHẬT CHÍNH THỨC {version} • ĐÃ SỬA CHỮA HOÀN TOÀN</div>
    </div>
    <div class="content">
      <div class="greeting">
        Kính gửi <strong>Đạo Hữu Phúc Nguyễn thiên</strong> (và Quý Đạo Hữu Tiên Lộ),<br><br>
        Ban Quản Trị <strong>Tiên Lộ Tu Thân &amp; Solo Leveling</strong> xin gửi lời tri ân chân thành và sâu sắc nhất tới Đạo Hữu vì đã liên tục đồng hành, đóng góp các phản hồi sự cố vô cùng quý báu cho đội ngũ phát triển.<br><br>
        Toàn bộ 3 vấn đề Đạo Hữu đã báo cáo qua hệ thống gồm <em>"Kho đồ bị mất toàn bộ vật phẩm"</em>, <em>"Không có nút dùng vật phẩm &amp; hitbox nút mua nhỏ"</em>, và <em>"Đề xuất thêm hướng dẫn sử dụng cùng đa dạng hóa nhiệm vụ"</em> đã được đội ngũ kỹ thuật xử lý triệt để trong phiên bản <strong>{version}</strong>:
      </div>

      <div class="box">
        <div class="box-title">🛠️ CHI TIẾT CÁC ĐIỂM ĐÃ KHẮC PHỤC &amp; NÂNG CẤP TRỌNG TÂM</div>
        
        <div class="issue-item">
          <span class="issue-title">1. Khôi Phục &amp; Lưu Trữ Vĩnh Viễn Kho Đồ (Túi Càn Khôn)</span>
          <span class="issue-desc">
            ✔ Đã tạo bảng dữ liệu chuyên biệt trên Supabase và bổ sung cơ chế tự động khôi phục từ lịch sử giao dịch.<br>
            ✔ Toàn bộ <strong>18x Tẩy Tủy Đan, 2x Hộ Mệnh Phù, 1x Tụ Linh Trận Kỳ, 2x Định Hồn Châu, 1x Tụ Khí Đan, 2x Tụ Khí Phù, 1x Thần Hành Phù, 1x Tẩy Tâm Phù, 3x Cố Thần Hoàn</strong> cùng tất cả vật phẩm đạo hữu từng mua đã được bảo toàn 100%, không bao giờ bị mất lại.
          </span>
        </div>

        <div class="issue-item">
          <span class="issue-title">2. Bổ Sung Nút "SỬ DỤNG" Trực Quan Trong Túi Đồ</span>
          <span class="issue-desc">
            ✔ Trên mỗi thẻ vật phẩm trong Túi Càn Khôn giờ đây đã có nút <strong>"SỬ DỤNG"</strong> nổi bật.<br>
            ✔ Đạo hữu chỉ cần bấm vào để nuốt đan dược nhận ngay hàng ngàn Linh Lực (EXP) bứt phá cảnh giới tức thì, hoặc kích hoạt bùa hộ mệnh gia trì chuỗi ngày rèn luyện.
          </span>
        </div>

        <div class="issue-item">
          <span class="issue-title">3. Tinh Chỉnh Hitbox Vùng Bấm &amp; Nút Mua Mượt Mà</span>
          <span class="issue-desc">
            ✔ Đã mở rộng hitbox tương tác trên toàn bộ thẻ vật phẩm tại Phù Lục Các (chạm bất kỳ đâu trên thẻ hoặc bấm nút Đổi Bảo đều mở ngay hộp thoại mua đồ).<br>
            ✔ Nút bấm số lượng (+ / -) và nút xác nhận mua to rõ, 1 chạm là ăn ngay, khắc phục triệt để cảm giác hitbox nhỏ.
          </span>
        </div>

        <div class="issue-item">
          <span class="issue-title">4. Ra Mắt "Bí Kíp Nhập Môn" (Hướng Dẫn Tân Thủ)</span>
          <span class="issue-desc">
            ✔ Bổ sung cẩm nang hướng dẫn mở đầu trực quan gồm 5 chương: Khởi đầu chiến dịch, Mệnh lệnh Daily Quests, 10 Đại cảnh giới đột phá, Chuỗi ngày Streak &amp; Thiên đạo xử phạt, Phù Lục Các &amp; Túi Càn Khôn.<br>
            ✔ Đạo hữu có thể mở lại cẩm nang bất cứ lúc nào qua biểu tượng cuốn sách ở góc màn hình hoặc trong mục Cài Đặt Cá Nhân.
          </span>
        </div>

        <div class="issue-item" style="margin-bottom: 0;">
          <span class="issue-title">5. Đa Dạng Hóa Hệ Thống Nhiệm Vụ &amp; Thanh Tiến Độ Rực Rỡ</span>
          <span class="issue-desc">
            ✔ Bổ sung hàng chục mẫu nhiệm vụ phong phú đa lĩnh vực: <strong>Làm Đẹp &amp; Đẹp Trai</strong> (Skincare sáng/tối, Mewing, tư thế đĩnh đạc...), <strong>Solo Leveling Thể Lực</strong> (Push-ups, Sit-ups, Squats, Chạy bộ, Nước lạnh...), Kỷ luật thép...<br>
            ✔ Loại bỏ hoàn toàn sự trùng lặp đơn điệu, bổ sung thanh tiến độ phần trăm % phát sáng hoàng kim giúp phần nhiệm vụ sinh động, tràn đầy động lực.
          </span>
        </div>
      </div>

      <div style="text-align: center; margin: 26px 0;">
        <p style="color: #94a3b8; font-size: 13.5px; margin-bottom: 14px;">Đạo hữu hãy cập nhật ngay phiên bản {version} để trải nghiệm:</p>
        <a href="https://tienlo.onrender.com" class="download-btn">🌐 TRANG CHỦ TIÊN LỘ &amp; TẢI BẢN MỚI</a>
        <br>
        <p style="font-size: 12.5px; color: #64748b; margin-top: 8px;">Tải thẳng APK: <a href="https://tienlo.onrender.com/download" style="color: #38bdf8;">https://tienlo.onrender.com/download</a></p>
      </div>

      <p style="color: #cbd5e1; font-size: 14px; line-height: 1.6; font-style: italic; border-left: 3px solid #f59e0b; padding-left: 14px;">
        "Đạo tâm kiên định, vạn kiếp bất diệt. Chúc Đạo Hữu Phúc Nguyễn thiên cùng chư vị đạo hữu tu vi tinh tiến, sớm ngày bứt phá cảnh giới, đắc đạo phi thăng!"
      </p>
    </div>
    <div class="footer">
      Tiên Lộ Tu Thân &amp; Solo Leveling • Hệ Thống Tự Động Chăm Sóc Người Tu Đạo<br>
      Email hỗ trợ: ngovanm691@gmail.com • Trang chủ: https://tienlo.onrender.com
    </div>
  </div>
</body>
</html>
"""

    msg = MIMEMultipart('alternative')
    msg['Subject'] = subject
    msg['From'] = f'"Tiên Lộ Tu Thân" <{smtp_user}>'
    msg['To'] = reporter_email
    msg['Cc'] = admin_email
    msg.attach(MIMEText(html_content, 'html'))

    try:
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=15)
        server.login(smtp_user, smtp_pass)
        server.sendmail(smtp_user, recipients, msg.as_string())
        server.quit()
        print(f"✅ Đã gửi email thông báo cập nhật sửa lỗi thành công tới {recipients}!")
        return True
    except Exception as e:
        print(f"❌ Lỗi gửi email: {e}")
        return False

if __name__ == '__main__':
    send_update_email()
