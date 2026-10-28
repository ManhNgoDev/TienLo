import { Injectable, Logger } from '@nestjs/common';
import nodemailer, { type Transporter } from 'nodemailer';
import { CreateBugReportDto } from './dto/create-bug-report.dto.js';
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
    const user = process.env.GMAIL_USER || process.env.SMTP_USER;
    const pass = process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASS || process.env.GMAIL_PASS;

    if (user && pass) {
      try {
        this.transporter = nodemailer.createTransport({
          service: 'gmail',
          auth: { user, pass },
        });
        this.logger.log(`Nodemailer Gmail Transporter đã sẵn sàng (Gửi từ: ${user})!`);
      } catch (err: any) {
        this.logger.warn(`Không thể khởi tạo Nodemailer: ${err.message}`);
        this.transporter = null;
      }
    } else {
      this.logger.warn(
        'GMAIL_USER hoặc GMAIL_APP_PASSWORD chưa được cấu hình trong .env. Báo cáo lỗi sẽ được lưu lại trong bộ nhớ và cơ sở dữ liệu. Thêm thông tin vào .env để gửi email tự động.',
      );
    }
  }

  async reportBug(dto: CreateBugReportDto): Promise<{ success: boolean; message: string; reportId: string }> {
    const reportId = `report-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const adminEmail = process.env.ADMIN_EMAIL || process.env.GMAIL_USER || 'ngovanm691@gmail.com';
    const nowIso = new Date().toISOString();

    const record: BugReportRecord = {
      id: reportId,
      title: dto.title.trim(),
      description: dto.description.trim(),
      category: dto.category?.trim() || 'GENERAL',
      screen: dto.screen?.trim() || 'UNKNOWN_SCREEN',
      userEmail: dto.userEmail?.trim() || 'Ẩn danh (Không cung cấp)',
      userId: dto.userId?.trim() || 'anonymous',
      deviceInfo: dto.deviceInfo?.trim() || 'Chưa xác định',
      stackTrace: dto.stackTrace?.trim(),
      appVersion: dto.appVersion?.trim() || '1.0.5',
      createdAt: nowIso,
      sentEmail: false,
    };

    // 1. Lưu vào danh sách gần đây
    this.recentReports.unshift(record);
    if (this.recentReports.length > 100) this.recentReports.pop();

    // 2. Thử lưu vào Supabase nếu có bảng
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

    // 3. Gửi email thông báo tới Gmail của Admin
    let emailSent = false;
    if (this.transporter) {
      try {
        const fromUser = process.env.GMAIL_USER || process.env.SMTP_USER || adminEmail;
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

        await this.transporter.sendMail({
          from: `"Tiên Lộ Bug Reporter" <${fromUser}>`,
          to: adminEmail,
          subject: `🚨 [TIÊN LỘ LỖI] [${record.category}] ${record.title}`,
          html: htmlContent,
        });

        emailSent = true;
        record.sentEmail = true;
        this.logger.log(`Đã gửi email báo cáo lỗi [${reportId}] thành công tới ${adminEmail}!`);
      } catch (mailErr: any) {
        this.logger.error(`Lỗi khi gửi email qua Gmail: ${mailErr.message}`);
      }
    } else {
      this.logger.warn(
        `[Feedback] Đã ghi nhận báo cáo [${reportId}]: "${record.title}". Email chưa gửi vì GMAIL_APP_PASSWORD chưa được cấu hình trong .env.`,
      );
    }

    return {
      success: true,
      message: emailSent
        ? 'Báo cáo sự cố đã được gửi trực tiếp tới hòm thư Quản Trị Viên qua Gmail!'
        : 'Báo cáo sự cố đã được tiếp nhận và lưu vào hệ thống!',
      reportId,
    };
  }

  getRecentReports(): BugReportRecord[] {
    return this.recentReports;
  }
}
