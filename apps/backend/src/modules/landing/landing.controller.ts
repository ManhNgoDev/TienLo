import { Controller, Get, Header, Res } from '@nestjs/common';
import type { Response } from 'express';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { AppService } from '../../app.service.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

@Controller()
export class LandingController {
  constructor(private readonly appService: AppService) {}

  @Get('logo.png')
  getLogo(@Res() res: Response) {
    const candidates = [
      path.resolve(process.cwd(), 'apps/backend/src/modules/landing/logo_tienlo.png'),
      path.resolve(process.cwd(), 'src/modules/landing/logo_tienlo.png'),
      path.resolve(process.cwd(), 'dist/modules/landing/logo_tienlo.png'),
      path.resolve(process.cwd(), 'apps/backend/dist/modules/landing/logo_tienlo.png'),
      path.join(__dirname, 'logo_tienlo.png'),
    ];

    for (const p of candidates) {
      if (fs.existsSync(p)) {
        res.setHeader('Content-Type', 'image/png');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return fs.createReadStream(p).pipe(res);
      }
    }
    return res.status(404).send('Logo not found');
  }

  @Get('download')
  async downloadApk(@Res() res: Response) {
    const versionInfo = await this.appService.getAppVersion();
    return res.redirect(versionInfo.downloadUrl);
  }

  @Get('download/apk')
  async downloadApkDirect(@Res() res: Response) {
    const versionInfo = await this.appService.getAppVersion();
    return res.redirect(versionInfo.downloadUrl);
  }

  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  async getLandingPage(): Promise<string> {
    const versionInfo = await this.appService.getAppVersion();
    const latestVersion = versionInfo.latestVersion || '1.0.1';
    const downloadUrl = versionInfo.downloadUrl || '/download';

    return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tiên Lộ (TienLo) • Thăng Cấp Bản Thân & Tu Chân Hiện Đại</title>
  <meta name="description" content="Ứng dụng phát triển bản thân, theo dõi thói quen game hóa theo phong cách Tu Tiên Huyền Huyễn kết hợp Hệ Thống Solo Leveling. Tải APK Android miễn phí.">
  <link rel="icon" type="image/png" href="/logo.png">
  <link rel="apple-touch-icon" href="/logo.png">
  
  <!-- Google Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Playfair+Display:ital,wght@0,600;0,700;1,600&display=swap" rel="stylesheet">
  
  <style>
    :root {
      --bg-dark: #060D17;
      --bg-card: rgba(12, 25, 41, 0.75);
      --bg-card-hover: rgba(18, 38, 63, 0.85);
      --gold-primary: #FBBF24;
      --gold-secondary: #E8B95E;
      --gold-border: rgba(197, 154, 68, 0.55);
      --gold-glow: rgba(251, 191, 36, 0.25);
      --text-main: #FFF6DF;
      --text-muted: #8BA5BA;
      --text-dim: #5A758D;
      --cyan-accent: #38BDF8;
      --orange-accent: #FB923C;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      -webkit-font-smoothing: antialiased;
    }

    body {
      background-color: var(--bg-dark);
      color: var(--text-main);
      font-family: 'Plus Jakarta Sans', sans-serif;
      overflow-x: hidden;
      line-height: 1.6;
      background-image: 
        radial-gradient(circle at 50% 0%, rgba(245, 158, 11, 0.12) 0%, transparent 60%),
        radial-gradient(circle at 10% 30%, rgba(56, 189, 248, 0.08) 0%, transparent 40%),
        radial-gradient(circle at 90% 70%, rgba(245, 158, 11, 0.08) 0%, transparent 50%);
      background-attachment: fixed;
    }

    /* Container */
    .container {
      max-width: 1140px;
      margin: 0 auto;
      padding: 0 24px;
    }

    /* Navbar */
    nav {
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      background: rgba(6, 13, 23, 0.75);
      border-bottom: 1px solid rgba(197, 154, 68, 0.25);
    }
    .nav-inner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      height: 72px;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text-main);
    }
    .logo-badge {
      width: 42px;
      height: 42px;
      border-radius: 12px;
      background: linear-gradient(135deg, #1E3A5F 0%, #0F2038 100%);
      border: 1.5px solid var(--gold-secondary);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      box-shadow: 0 0 16px var(--gold-glow);
    }
    .logo-text {
      font-family: 'Cinzel', serif;
      font-size: 22px;
      font-weight: 800;
      letter-spacing: 2px;
      background: linear-gradient(135deg, #FFF6DF 0%, #FBBF24 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .nav-actions {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .btn-nav-download {
      background: linear-gradient(135deg, #D97706 0%, #B45309 100%);
      color: #FFF;
      padding: 10px 20px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 13.5px;
      text-decoration: none;
      border: 1px solid var(--gold-primary);
      box-shadow: 0 4px 14px rgba(217, 119, 6, 0.35);
      transition: all 0.25s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .btn-nav-download:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(251, 191, 36, 0.45);
    }

    /* Hero Section */
    .hero {
      padding: 80px 0 60px;
      text-align: center;
      position: relative;
    }
    .hero-tag {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 16px;
      border-radius: 30px;
      background: rgba(232, 185, 94, 0.12);
      border: 1px solid rgba(232, 185, 94, 0.45);
      font-size: 12px;
      font-weight: 700;
      color: var(--gold-secondary);
      letter-spacing: 1.5px;
      margin-bottom: 24px;
      animation: float 4s ease-in-out infinite;
    }
    .hero h1 {
      font-family: 'Cinzel', serif;
      font-size: clamp(34px, 5.5vw, 62px);
      font-weight: 900;
      line-height: 1.15;
      letter-spacing: 1px;
      margin-bottom: 20px;
      background: linear-gradient(135deg, #FFFFFF 0%, #FFF6DF 40%, #FBBF24 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .hero-desc {
      max-width: 680px;
      margin: 0 auto 36px;
      font-size: clamp(15px, 2vw, 18px);
      color: var(--text-muted);
      line-height: 1.7;
    }
    .hero-desc strong {
      color: var(--text-main);
      font-weight: 600;
    }

    /* Big Download CTA */
    .cta-wrapper {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 14px;
      margin-bottom: 50px;
    }
    .btn-hero-download {
      background: linear-gradient(135deg, #F59E0B 0%, #D97706 60%, #92400E 100%);
      color: #FFFFFF;
      padding: 18px 42px;
      border-radius: 18px;
      font-size: 18px;
      font-weight: 800;
      text-decoration: none;
      border: 1.5px solid #FDE68A;
      box-shadow: 0 10px 30px rgba(245, 158, 11, 0.45);
      transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      display: inline-flex;
      align-items: center;
      gap: 12px;
    }
    .btn-hero-download:hover {
      transform: translateY(-3px) scale(1.02);
      box-shadow: 0 16px 40px rgba(251, 191, 36, 0.6);
    }
    .cta-meta {
      font-size: 13px;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
      justify-content: center;
    }
    .cta-meta span {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }

    /* Phone Mockup Showcase */
    .mockup-container {
      max-width: 420px;
      margin: 0 auto 80px;
      position: relative;
    }
    .phone-mockup {
      background: linear-gradient(160deg, #132235 0%, #091726 100%);
      border: 2px solid var(--gold-border);
      border-radius: 36px;
      padding: 24px 20px;
      box-shadow: 
        0 20px 60px rgba(0, 0, 0, 0.8),
        0 0 40px var(--gold-glow);
      text-align: left;
    }
    .phone-top-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 11px;
      color: var(--gold-secondary);
      font-weight: 700;
      letter-spacing: 1.2px;
      margin-bottom: 16px;
      border-bottom: 1px solid rgba(197, 154, 68, 0.2);
      padding-bottom: 10px;
    }
    .mockup-card {
      background: rgba(12, 25, 41, 0.8);
      border-radius: 18px;
      padding: 16px;
      border: 1px solid rgba(197, 154, 68, 0.35);
      margin-bottom: 14px;
    }
    .mockup-card-title {
      font-size: 11px;
      color: var(--gold-secondary);
      font-weight: 700;
      letter-spacing: 1px;
      margin-bottom: 6px;
    }
    .mockup-card-main {
      font-size: 15px;
      font-weight: 700;
      color: #FFF;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .quest-pill {
      background: rgba(56, 189, 248, 0.15);
      color: var(--cyan-accent);
      padding: 3px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
    }
    .skill-bar-row {
      margin-top: 10px;
    }
    .skill-bar-label {
      display: flex;
      justify-content: space-between;
      font-size: 11.5px;
      margin-bottom: 4px;
      color: #BAC7D5;
    }
    .skill-bar-track {
      height: 6px;
      background: #0C1624;
      border-radius: 3px;
      overflow: hidden;
    }
    .skill-bar-fill {
      height: 100%;
      border-radius: 3px;
    }

    /* Features Grid */
    .features-section {
      padding: 40px 0 80px;
    }
    .section-header {
      text-align: center;
      margin-bottom: 50px;
    }
    .section-tag {
      font-size: 11.5px;
      font-weight: 700;
      color: var(--gold-secondary);
      letter-spacing: 2px;
      text-transform: uppercase;
      margin-bottom: 8px;
    }
    .section-title {
      font-family: 'Cinzel', serif;
      font-size: clamp(26px, 3.5vw, 38px);
      font-weight: 800;
      color: #FFF;
    }

    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 24px;
    }
    .feature-card {
      background: var(--bg-card);
      border: 1.2px solid var(--gold-border);
      border-radius: 24px;
      padding: 28px 24px;
      backdrop-filter: blur(12px);
      transition: all 0.3s ease;
      position: relative;
      overflow: hidden;
    }
    .feature-card:hover {
      transform: translateY(-6px);
      border-color: var(--gold-primary);
      box-shadow: 0 16px 36px rgba(0, 0, 0, 0.6), 0 0 24px var(--gold-glow);
    }
    .feature-icon {
      width: 52px;
      height: 52px;
      border-radius: 16px;
      background: linear-gradient(135deg, rgba(245, 158, 11, 0.2) 0%, rgba(217, 119, 6, 0.05) 100%);
      border: 1.5px solid var(--gold-secondary);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      margin-bottom: 20px;
    }
    .feature-title {
      font-family: 'Playfair Display', serif;
      font-size: 20px;
      font-weight: 700;
      color: #FFF6DF;
      margin-bottom: 12px;
    }
    .feature-desc {
      font-size: 13.5px;
      color: var(--text-muted);
      line-height: 1.6;
    }

    /* 3 Step Installation */
    .steps-section {
      background: rgba(12, 25, 41, 0.5);
      border-top: 1px solid rgba(197, 154, 68, 0.2);
      border-bottom: 1px solid rgba(197, 154, 68, 0.2);
      padding: 80px 0;
    }
    .steps-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 30px;
      margin-top: 40px;
    }
    .step-card {
      background: #091726;
      border: 1px solid rgba(197, 154, 68, 0.35);
      border-radius: 20px;
      padding: 28px 24px;
      position: relative;
    }
    .step-num {
      position: absolute;
      top: -16px;
      left: 24px;
      background: linear-gradient(135deg, #D97706, #B45309);
      color: #FFF;
      width: 34px;
      height: 34px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      font-size: 15px;
      border: 1px solid var(--gold-primary);
    }
    .step-title {
      font-size: 17px;
      font-weight: 700;
      color: #FFF;
      margin: 10px 0 8px;
    }
    .step-desc {
      font-size: 13.5px;
      color: var(--text-muted);
      line-height: 1.55;
    }

    /* Footer */
    footer {
      padding: 50px 0 40px;
      text-align: center;
      border-top: 1px solid rgba(197, 154, 68, 0.2);
      color: var(--text-dim);
      font-size: 13px;
    }
    footer a {
      color: var(--gold-secondary);
      text-decoration: none;
    }
    footer a:hover {
      text-decoration: underline;
    }

    @keyframes float {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-6px); }
    }

    @media (max-width: 640px) {
      .hero { padding: 50px 0 40px; }
      .btn-hero-download { width: 100%; justify-content: center; }
    }
  </style>
</head>
<body>

  <!-- Navigation -->
  <nav>
    <div class="container nav-inner">
      <a href="/" class="logo">
        <img src="/logo.png" alt="Tiên Lộ" style="width: 44px; height: 44px; border-radius: 12px; border: 1.5px solid var(--gold-secondary); object-fit: cover; box-shadow: 0 0 16px var(--gold-glow);">
        <div class="logo-text">TIÊN LỘ</div>
      </a>
      <div class="nav-actions">
        <a href="${downloadUrl}" class="btn-nav-download" id="nav-download-btn">
          <span>⬇ Tải APK (v${latestVersion})</span>
        </a>
      </div>
    </div>
  </nav>

  <!-- Hero Section -->
  <section class="hero">
    <div class="container">
      <div style="margin-bottom: 24px;">
        <img src="/logo.png" alt="Tiên Lộ Logo" style="width: 140px; height: 140px; border-radius: 34px; border: 2.5px solid var(--gold-secondary); box-shadow: 0 16px 40px rgba(0, 0, 0, 0.7), 0 0 40px var(--gold-glow); object-fit: cover;">
      </div>
      <div class="hero-tag">
        <span>✨ GAMIFIED HABIT &amp; SELF-IMPROVEMENT APP</span>
      </div>
      <h1>TU TIÊN LỘ<br>THĂNG CẤP ĐỜI THỰC</h1>
      <p class="hero-desc">
        Biến từng hiệp chống đẩy, trang sách đọc hay cốc nước uống thành luồng <strong>linh lực EXP</strong> đột phá cảnh giới từ <strong>Phàm Nhân đến Phi Thăng</strong>. Hệ thống nhiệm vụ chuẩn phong cách <strong>Solo Leveling</strong> kết hợp cố vấn <strong>Thiên Đạo AI</strong>.
      </p>

      <div class="cta-wrapper">
        <a href="${downloadUrl}" class="btn-hero-download" id="hero-download-btn">
          <span style="font-size: 22px;">⚡</span>
          <span>TẢI BẢN CÀI ĐẶT APK (v${latestVersion})</span>
        </a>
        <div class="cta-meta">
          <span>📱 Dành cho thiết bị Android</span>
          <span>•</span>
          <span>🔄 Tự động cập nhật qua OTA</span>
          <span>•</span>
          <span>🛡️ An toàn, không chứa quảng cáo</span>
        </div>
      </div>

      <!-- Live Mockup -->
      <div class="mockup-container">
        <div class="phone-mockup">
          <div class="phone-top-bar">
            <span>CHƯƠNG I • CHUỖI NGÀY: 7</span>
            <span>CẢNH GIỚI: LUYỆN KHÍ TẦNG 2</span>
          </div>

          <div class="mockup-card">
            <div class="mockup-card-title">NHIỆM VỤ HÀNG NGÀY • SOLO LEVELING</div>
            <div class="mockup-card-main">
              <span>Chống đẩy 100 cái &amp; Squat 100 cái</span>
              <span class="quest-pill">+350 EXP</span>
            </div>
            <div style="font-size: 11.5px; color: #8BA5BA; margin-top: 4px;">
              Chia làm 4 hiệp chuẩn form, nghỉ 60s giữa hiệp.
            </div>
          </div>

          <div class="mockup-card">
            <div class="mockup-card-title">CĂN CỐT NĂNG LỰC ĐỜI THỰC</div>
            
            <div class="skill-bar-row">
              <div class="skill-bar-label">
                <span>Thể chất</span>
                <span style="color: #FB923C; font-weight: 700;">85%</span>
              </div>
              <div class="skill-bar-track">
                <div class="skill-bar-fill" style="width: 85%; background: linear-gradient(90deg, #EA580C, #FB923C);"></div>
              </div>
            </div>

            <div class="skill-bar-row">
              <div class="skill-bar-label">
                <span>Định lực tập trung</span>
                <span style="color: #2DD4BF; font-weight: 700;">72%</span>
              </div>
              <div class="skill-bar-track">
                <div class="skill-bar-fill" style="width: 72%; background: linear-gradient(90deg, #0D9488, #2DD4BF);"></div>
              </div>
            </div>

            <div class="skill-bar-row">
              <div class="skill-bar-label">
                <span>Trí thức</span>
                <span style="color: #FDE047; font-weight: 700;">68%</span>
              </div>
              <div class="skill-bar-track">
                <div class="skill-bar-fill" style="width: 68%; background: linear-gradient(90deg, #CA8A04, #FDE047);"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- Features Grid -->
  <section class="features-section">
    <div class="container">
      <div class="section-header">
        <div class="section-tag">HỆ THỐNG ĐẶC SẮC</div>
        <h2 class="section-title">Tại Sao Nên Chọn Tiên Lộ?</h2>
      </div>

      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">🏋️‍♂️</div>
          <h3 class="feature-title">Solo Leveling Quests</h3>
          <p class="feature-desc">
            Không còn những khẩu hiệu sáo rỗng. Nhiệm vụ đo lường cụ thể từng số cái chống đẩy, số km chạy bộ, số trang sách đọc. Nếu bỏ cuộc, Thiên Đạo sẽ giáng lâm hình phạt trừ EXP!
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🌌</div>
          <h3 class="feature-title">10 Cảnh Giới Tu Chân</h3>
          <p class="feature-desc">
            Từ Phàm Nhân, Luyện Khí, Trúc Cơ đến Phi Tiên. Mỗi hành động kỷ luật trong đời thực đều được tích lũy thành linh lực EXP và linh thạch để độ kiếp thăng cấp.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">📊</div>
          <h3 class="feature-title">Skill Tree Đời Thực</h3>
          <p class="feature-desc">
            Đo lường chính xác 4 chỉ số cốt lõi: Thể chất, Trí thức, Định lực tập trung và Giao tiếp tâm thái dựa trên dữ liệu hoàn thành nhiệm vụ thực tế của bạn.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon">🤖</div>
          <h3 class="feature-title">Thiên Đạo AI Đồng Hành</h3>
          <p class="feature-desc">
            Trí tuệ nhân tạo thế hệ mới đóng vai trò Thiên Đạo, phân tích nhịp độ sinh hoạt, gợi ý khung giờ rèn luyện tốt nhất và đồng hành sát sao trên từng chặng đường.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- 3 Steps Installation -->
  <section class="steps-section">
    <div class="container">
      <div class="section-header">
        <div class="section-tag">HƯỚNG DẪN CÀI ĐẶT</div>
        <h2 class="section-title">3 Bước Để Bắt Đầu Tu Tiên</h2>
      </div>

      <div class="steps-grid">
        <div class="step-card">
          <div class="step-num">1</div>
          <h4 class="step-title">Tải Bản Cài Đặt APK</h4>
          <p class="step-desc">
            Bấm vào nút tải xuống để tải tệp <code>TienLo-release.apk</code> trực tiếp về máy Android của bạn.
          </p>
        </div>

        <div class="step-card">
          <div class="step-num">2</div>
          <h4 class="step-title">Mở Tệp &amp; Cài Đặt</h4>
          <p class="step-desc">
            Nhấn mở file APK vừa tải và chọn "Cài đặt". Nếu máy hỏi cấp quyền nguồn này, hãy bật cho phép để tiến hành.
          </p>
        </div>

        <div class="step-card">
          <div class="step-num">3</div>
          <h4 class="step-title">Tự Động Cập Nhật Về Sau</h4>
          <p class="step-desc">
            Sau khi cài xong, các phiên bản mới sau này sẽ được cập nhật tự động ngay trong ứng dụng với 1 chạm!
          </p>
        </div>
      </div>

      <div style="text-align: center; margin-top: 48px;">
        <a href="${downloadUrl}" class="btn-hero-download">
          <span>⬇ TẢI TIÊN LỘ APK NGAY</span>
        </a>
      </div>
    </div>
  </section>

  <!-- Footer -->
  <footer>
    <div class="container">
      <p style="margin-bottom: 8px;">
        <strong>Tiên Lộ (TienLo)</strong> • Hệ thống tu chân hiện đại &amp; Gamified Self-Improvement
      </p>
      <p>
        Phát triển bởi <a href="https://github.com/ManhNgoDev/TienLo" target="_blank" rel="noopener">ManhNgoDev</a> • Vận hành trên Render Cloud
      </p>
    </div>
  </footer>

</body>
</html>`;
  }
}
