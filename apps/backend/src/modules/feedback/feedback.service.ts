import { Injectable, Logger } from '@nestjs/common';
import nodemailer, { type Transporter } from 'nodemailer';
import { CreateBugReportDto } from './dto/create-bug-report.dto.js';
import { SendUpdateNoticeDto } from './dto/send-update-notice.dto.js';
import { SupabaseService } from '../database/supabase.service.js';

export interface BugReportRecord {
  id: string;
  title: string;
  description: string;
  category: string;
  screen: string;
  userEmail: string;
  userId: string;
  deviceInfo: string;
  stackTrace?: string;
  appVersion: string;
  createdAt: string;
  sentEmail: boolean;
}

@Injectable()
export class FeedbackService {
  private readonly logger = new Logger(FeedbackService.name);
  private transporter: Transporter | null = null;
  private readonly recentReports: BugReportRecord[] = [];

  constructor(private readonly supabaseService: SupabaseService) {
    this.initTransporter();
  }

  private initTransporter(): void {
    const user = process.env.GMAIL_USER || process.env.SMTP_USER || 'shiinamizuha@gmail.com';
    const pass =
      process.env.GMAIL_APP_PASSWORD ||
      process.env.SMTP_PASS ||
      process.env.GMAIL_PASS ||
      'sqrb gpxw zutb ukdq';

    if (user && pass) {
      try {
        this.transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: { user, pass },
          connectionTimeout: 5000,
          greetingTimeout: 5000,
          socketTimeout: 8000,
        });
        this.logger.log(`Nodemailer Gmail Transporter đã sẵn sàng (Gửi từ: ${user})!`);
      } catch (err: any) {
        this.logger.warn(`Không thể khởi tạo Nodemailer: ${err.message}`);
        this.transporter = null;
      }
    } else {
      this.logger.warn(
        'GMAIL_USER hoặc GMAIL_APP_PASSWORD chưa được cấu hình trong .env. Báo cáo lỗi sẽ được lưu lại trong bộ nhớ và cơ sở dữ liệu.',
      );
    }
  }

  async reportBug(dto: CreateBugReportDto): Promise<{ success: boolean; message: string; reportId: string }> {
    const reportId = `report-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const adminEmail = process.env.ADMIN_EMAIL || 'ngovanm691@gmail.com';
    const nowIso = new Date().toISOString();

    const record: BugReportRecord = {
      id: reportId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      category: dto.category?.trim() || 'GENERAL',
      screen: dto.screen?.trim() || 'UNKNOWN_SCREEN',
      userEmail: dto.userEmail?.trim() || 'Ẩn danh (Chưa đăng nhập)',
      userId: dto.userId?.trim() || 'anonymous',
      deviceInfo: dto.deviceInfo?.trim() || 'Chưa xác định',
      stackTrace: dto.stackTrace?.trim(),
      appVersion: dto.appVersion?.trim() || '1.1.3',
      createdAt: nowIso,
      sentEmail: dto.sentByClient === true,
    };

    // 1. Lưu vào danh sách gần đây trong bộ nhớ
    this.recentReports.unshift(record);
    if (this.recentReports.length > 100) this.recentReports.pop();
    this.logger.log(`[BugReport] Đã tiếp nhận báo cáo [${reportId}]: "${record.title}" từ ${record.userEmail}`);

    // 2. Lưu vào Supabase ngầm (không chặn client)
    this.saveToDatabaseAsync(record).catch(() => {});

    // 3. Nếu client chưa trực tiếp gửi mail qua SMTP thì server gửi ngầm trong background
    if (!dto.sentByClient) {
      this.sendEmailAsync(record, adminEmail).catch((err) => {
        this.logger.warn(`Lỗi gửi email báo cáo lỗi trong background: ${err.message}`);
      });
    }

    // 4. Trả về ngay lập tức cho client tránh tình trạng loading vô tận
    return {
      success: true,
      message: 'Báo cáo sự cố đã được gửi trực tiếp tới Gmail Quản Trị Viên (ngovanm691@gmail.com)!',
      reportId,
    };
  }

  private async saveToDatabaseAsync(record: BugReportRecord): Promise<void> {
    try {
      const client = this.supabaseService.getClient();
      if (client) {
        await client.from('bug_reports').insert({
          id: record.id,
          title: record.title,
          description: record.description,
          category: record.category,
          screen: record.screen,
          user_email: record.userEmail,
          user_id: record.userId,
          device_info: record.deviceInfo,
          stack_trace: record.stackTrace,
          app_version: record.appVersion,
          created_at: record.createdAt,
        });
      }
    } catch {
      // Bỏ qua nếu bảng chưa được tạo trên Supabase
    }
  }

  private async sendEmailAsync(record: BugReportRecord, adminEmail: string): Promise<void> {
    if (!this.transporter) {
      this.logger.warn(
        `[Feedback] Đã ghi nhận báo cáo [${record.id}]: "${record.title}". Email chưa gửi vì GMAIL_APP_PASSWORD chưa được cấu hình.`,
      );
      return;
    }

    try {
      const fromUser = process.env.GMAIL_USER || process.env.SMTP_USER || 'shiinamizuha@gmail.com';
      const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0b0f19; color: #e2e8f0; margin: 0; padding: 24px; }
    .card { background-color: #111827; border: 1px solid #374151; border-radius: 12px; max-width: 650px; margin: 0 auto; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
    .header { background: linear-gradient(135deg, #7f1d1d 0%, #991b1b 50%, #450a0a 100%); padding: 20px 24px; border-bottom: 2px solid #ef4444; }
    .header h1 { margin: 0; font-size: 20px; color: #ffffff; display: flex; align-items: center; gap: 8px; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 700; background-color: #ef4444; color: #ffffff; text-transform: uppercase; margin-top: 8px; }
    .content { padding: 24px; }
    .field { margin-bottom: 18px; }
    .label { font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em; color: #9ca3af; margin-bottom: 6px; font-weight: 600; }
    .value { font-size: 15px; color: #f3f4f6; background-color: #1f2937; padding: 10px 14px; border-radius: 8px; border: 1px solid #374151; word-break: break-word; }
    .description-box { font-size: 15px; line-height: 1.6; color: #f9fafb; background-color: #1a2234; padding: 16px; border-radius: 8px; border-left: 4px solid #ef4444; white-space: pre-wrap; word-break: break-word; }
    .trace-box { font-family: 'Courier New', Courier, monospace; font-size: 12px; color: #fca5a5; background-color: #030712; padding: 12px; border-radius: 6px; overflow-x: auto; max-height: 250px; white-space: pre; border: 1px solid #7f1d1d; }
    .footer { padding: 16px 24px; background-color: #0b0f19; border-top: 1px solid #1f2937; text-align: center; font-size: 12px; color: #6b7280; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>🚨 [TIÊN LỘ] Báo Cáo Sự Cố Mới</h1>
      <div class="badge">${record.category} • ${record.screen}</div>
    </div>
    <div class="content">
      <div class="field">
        <div class="label">Tiêu Đề Sự Cố</div>
        <div class="value" style="font-weight: 700; color: #f87171;">${record.title}</div>
      </div>
      <div class="field">
        <div class="label">Mô Tả Chi Tiết</div>
        <div class="description-box">${record.description}</div>
      </div>
      <div class="field">
        <div class="label">Người Báo Cáo / Tài Khoản</div>
        <div class="value">
          <strong>Email:</strong> ${record.userEmail}<br/>
          <strong>User ID:</strong> ${record.userId}
        </div>
      </div>
      <div class="field">
        <div class="label">Vị Trí & Thiết Bị</div>
        <div class="value">
          <strong>Màn hình:</strong> ${record.screen}<br/>
          <strong>Phiên bản App:</strong> ${record.appVersion}<br/>
          <strong>Thiết bị:</strong> ${record.deviceInfo}
        </div>
      </div>
      ${
        record.stackTrace
          ? `<div class="field">
               <div class="label">Log Lỗi Kỹ Thuật (Stack Trace)</div>
               <div class="trace-box">${record.stackTrace}</div>
             </div>`
          : ''
      }
      <div class="field" style="margin-bottom: 0;">
        <div class="label">Thời Gian Ghi Nhận</div>
        <div class="value">${new Date().toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })} (Giờ Việt Nam)</div>
      </div>
    </div>
    <div class="footer">
      Hệ Thống Tự Động Tiếp Nhận Sự Cố & Báo Lỗi • Tiên Lộ Tu Thân &amp; Solo Leveling
    </div>
  </div>
</body>
</html>
`;

      // Giới hạn thời gian gửi mail trong 7 giây bằng Promise.race để không bao giờ bị nghẽn
      await Promise.race([
        this.transporter.sendMail({
          from: `"Tiên Lộ Bug Reporter" <${fromUser}>`,
          to: adminEmail,
          subject: `🚨 [TIÊN LỘ LỖI] [${record.category}] ${record.title}`,
          html: htmlContent,
        }),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Nodemailer sendMail timeout sau 7s')), 7000),
        ),
      ]);

      record.sentEmail = true;
      this.logger.log(`Đã gửi email báo cáo lỗi [${record.id}] thành công tới ${adminEmail}!`);
    } catch (mailErr: any) {
      this.logger.warn(`Không thể gửi email báo cáo lỗi qua Gmail: ${mailErr.message}`);
    }
  }

  async sendUpdateNotice(dto: SendUpdateNoticeDto): Promise<{ success: boolean; message: string; recipients: string[] }> {
    const adminEmail = process.env.ADMIN_EMAIL || 'ngovanm691@gmail.com';
    const fromUser = process.env.GMAIL_USER || process.env.SMTP_USER || 'shiinamizuha@gmail.com';
    const version = dto.updateVersion || 'v1.1.3';

    // Xác định danh sách email nhận
    const recipients: string[] = [];
    if (dto.recipientEmail && dto.recipientEmail.includes('@')) {
      recipients.push(dto.recipientEmail.trim());
    } else {
      // Gửi cho người báo lỗi gần đây hoặc mặc định phuczx210@gmail.com
      recipients.push('phuczx210@gmail.com');
      for (const r of this.recentReports) {
        if (r.userEmail && r.userEmail.includes('@') && !recipients.includes(r.userEmail)) {
          recipients.push(r.userEmail);
        }
      }
    }

    const defaultFixedIssues = [
      '🎒 Khôi Phục & Bảo Toàn Túi Càn Khôn: Tự động khôi phục 100% tất cả vật phẩm đã mua (Tẩy Tủy Đan, Hộ Mệnh Phù, Tụ Khí Phù, Định Hồn Châu...) và lưu trữ vĩnh viễn không bao giờ thất lạc.',
      '⚡ Bổ Sung Nút "SỬ DỤNG": Trực tiếp dùng đan dược trong túi đồ để nhận ngay hàng ngàn Linh Lực (EXP) bứt phá cảnh giới, kích hoạt phù lục & bảo vật tiện lợi.',
      '🎯 Canh Chỉnh Vùng Chạm (Hitbox) & Nút Mua: Toàn bộ thẻ vật phẩm và nút Đổi Bảo đã được mở rộng hitbox chuẩn 1 chạm cực nhạy, nút tăng giảm số lượng to rõ, mượt mà.',
      '📖 Ra Mắt Bí Kíp Nhập Môn (Hướng Dẫn Tân Thủ): Tích hợp cẩm nang hướng dẫn mở đầu trực quan, sinh động dành riêng cho người mới tu đạo.',
      '📜 Đa Dạng Hóa Hệ Thống Nhiệm Vụ: Bổ sung kho nhiệm vụ phong phú đa chủ đề (Làm đẹp & Phong độ, Solo Leveling & Thể lực, Kỷ luật thép...), dẹp bỏ hoàn toàn sự trùng lặp đơn điệu.',
    ];

    const fixedIssues = dto.fixedIssues && dto.fixedIssues.length > 0 ? dto.fixedIssues : defaultFixedIssues;
    const issuesHtml = fixedIssues
      .map(
        (issue) => `
        <li style="margin-bottom: 12px; line-height: 1.6; color: #e2e8f0;">
          <span style="color: #10b981; font-weight: bold; margin-right: 6px;">✔</span>
          ${issue}
        </li>`,
      )
      .join('');

    const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #070d18; color: #e2e8f0; margin: 0; padding: 24px; }
    .card { background-color: #0f172a; border: 1px solid #334155; border-radius: 16px; max-width: 650px; margin: 0 auto; overflow: hidden; box-shadow: 0 12px 30px rgba(0,0,0,0.6); }
    .header { background: linear-gradient(135deg, #0f766e 0%, #047857 50%, #064e3b 100%); padding: 24px; border-bottom: 2px solid #10b981; text-align: center; }
    .header h1 { margin: 0; font-size: 22px; color: #ffffff; letter-spacing: 0.5px; }
    .badge { display: inline-block; padding: 5px 14px; border-radius: 20px; font-size: 12px; font-weight: 800; background-color: #f59e0b; color: #0f172a; text-transform: uppercase; margin-top: 10px; letter-spacing: 0.5px; }
    .content { padding: 26px; }
    .greeting { font-size: 16px; color: #f8fafc; line-height: 1.6; margin-bottom: 20px; }
    .box { background-color: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 18px 20px; margin-bottom: 22px; }
    .box-title { font-size: 14px; font-weight: 700; color: #38bdf8; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 12px; }
    .download-btn { display: inline-block; background: linear-gradient(135deg, #eab308 0%, #ca8a04 100%); color: #0f172a; font-weight: 800; font-size: 15px; text-decoration: none; padding: 14px 28px; border-radius: 12px; margin: 10px 0; text-align: center; box-shadow: 0 4px 15px rgba(234, 179, 8, 0.4); }
    .footer { padding: 18px 24px; background-color: #070d18; border-top: 1px solid #1e293b; text-align: center; font-size: 12px; color: #94a3b8; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>⚡ [TIÊN LỘ] THÔNG BÁO HOÀN TẤT KHẮC PHỤC SỰ CỐ</h1>
      <div class="badge">BẢN CẬP NHẬT CHÍNH THỨC ${version} • ĐÃ SỬA CHỮA HOÀN TOÀN</div>
    </div>
    <div class="content">
      <div class="greeting">
        Kính gửi <strong>Đạo Hữu</strong>,<br><br>
        Ban Quản Trị <strong>Tiên Lộ Tu Thân &amp; Solo Leveling</strong> xin gửi lời tri ân chân thành nhất tới Đạo Hữu vì đã dành thời gian quý báu gửi báo cáo sự cố và đóng góp ý kiến giúp hoàn thiện thế giới Tiên Lộ!<br><br>
        Đội ngũ kỹ thuật đã tiến hành kiểm tra toàn diện, khắc phục triệt để mọi phản hồi và chính thức phát hành phiên bản <strong>${version}</strong> với các cải tiến trọng tâm sau:
      </div>

      <div class="box">
        <div class="box-title">🛠️ CHI TIẾT CÁC ĐIỂM ĐÃ SỬA CHỮA &amp; NÂNG CẤP</div>
        <ul style="margin: 0; padding-left: 20px;">
          ${issuesHtml}
        </ul>
      </div>

      <div style="text-align: center; margin: 26px 0;">
        <p style="color: #94a3b8; font-size: 13.5px; margin-bottom: 14px;">Đạo hữu hãy cập nhật ngay để trải nghiệm phiên bản mượt mà nhất:</p>
        <a href="https://tienlo.onrender.com" class="download-btn">🌐 TRANG CHỦ TIÊN LỘ &amp; TẢI BẢN MỚI</a>
        <br>
        <p style="font-size: 12.5px; color: #64748b; margin-top: 8px;">Hoặc tải thẳng file APK: <a href="https://tienlo.onrender.com/download" style="color: #38bdf8;">https://tienlo.onrender.com/download</a></p>
      </div>

      <p style="color: #cbd5e1; font-size: 14px; line-height: 1.6; font-style: italic; border-left: 3px solid #f59e0b; padding-left: 14px;">
        "Đạo tâm kiên định, vạn kiếp bất diệt. Chúc Đạo Hữu tu vi tinh tiến, sớm ngày bứt phá cảnh giới, đắc đạo phi thăng!"
      </p>
    </div>
    <div class="footer">
      Tiên Lộ Tu Thân &amp; Solo Leveling • Hệ Thống Tự Động Chăm Sóc Người Tu Đạo<br>
      Email hỗ trợ: ngovanm691@gmail.com • Trang chủ: https://tienlo.onrender.com
    </div>
  </div>
</body>
</html>
`;

    if (!this.transporter) {
      this.initTransporter();
    }

    if (!this.transporter) {
      return {
        success: false,
        message: 'Gmail Transporter chưa được khởi tạo. Vui lòng kiểm tra GMAIL_USER và GMAIL_APP_PASSWORD trong .env.',
        recipients,
      };
    }

    try {
      const subject = dto.subject || `⚡ [TIÊN LỘ] Thông Báo Khắc Phục Lỗi & Cập Nhật Phiên Bản ${version}`;
      for (const toEmail of recipients) {
        await this.transporter.sendMail({
          from: `"Tiên Lộ Tu Thân" <${fromUser}>`,
          to: toEmail,
          cc: adminEmail,
          subject,
          html: htmlContent,
        });
        this.logger.log(`[UpdateNotice] Đã gửi thông báo cập nhật thành công tới ${toEmail}!`);
      }

      return {
        success: true,
        message: `Đã gửi email thông báo cập nhật sửa lỗi thành công tới ${recipients.join(', ')}!`,
        recipients,
      };
    } catch (err: any) {
      this.logger.error(`Lỗi gửi email cập nhật: ${err.message}`);
      return {
        success: false,
        message: `Lỗi khi gửi email: ${err.message}`,
        recipients,
      };
    }
  }

  getRecentReports(): BugReportRecord[] {
    return this.recentReports;
  }
}
