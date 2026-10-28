export function getLandingHtml(
  latestVersion: string,
  downloadUrl: string = '/download',
  githubReleaseUrl: string = 'https://github.com/ManhNgoDev/TienLo/releases/latest',
): string {
  return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tiên Lộ • Hệ Thống Tu Chân & Thăng Cấp Bản Thân</title>
  <meta name="description" content="Ứng dụng phát triển bản thân, theo dõi thói quen game hóa theo phong cách Tu Tiên Huyền Huyễn kết hợp Hệ Thống Solo Leveling. Tải APK Android miễn phí.">
  <link rel="icon" type="image/png" href="/logo.png">
  <link rel="shortcut icon" type="image/png" href="/logo.png">
  <link rel="apple-touch-icon" href="/logo.png">
  
  <!-- Google Fonts (Playfair Display & Plus Jakarta Sans with full Vietnamese glyph support) -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,600;0,700;0,800;0,900;1,600;1,700&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  
  <style>
    :root {
      --bg-dark: #050B14;
      --bg-card: rgba(10, 22, 38, 0.72);
      --bg-card-hover: rgba(16, 34, 58, 0.88);
      --gold-primary: #FBBF24;
      --gold-secondary: #E8B95E;
      --gold-border: rgba(197, 154, 68, 0.45);
      --gold-glow: rgba(251, 191, 36, 0.22);
      --text-main: #FFF6DF;
      --text-muted: #94A3B8;
      --text-dim: #64748B;
      --cyan-accent: #38BDF8;
      --orange-accent: #FB923C;
      --emerald-accent: #34D399;
    }

    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      -webkit-font-smoothing: antialiased;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      background-color: var(--bg-dark);
      color: var(--text-main);
      font-family: 'Plus Jakarta Sans', sans-serif;
      overflow-x: hidden;
      line-height: 1.6;
      background-image: 
        radial-gradient(circle at 50% 0%, rgba(245, 158, 11, 0.14) 0%, transparent 60%),
        radial-gradient(circle at 15% 35%, rgba(56, 189, 248, 0.08) 0%, transparent 45%),
        radial-gradient(circle at 85% 65%, rgba(245, 158, 11, 0.09) 0%, transparent 50%),
        radial-gradient(circle at 50% 90%, rgba(52, 211, 153, 0.06) 0%, transparent 45%);
      background-attachment: fixed;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 24px;
    }

    /* Navbar */
    nav {
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
      background: rgba(5, 11, 20, 0.82);
      border-bottom: 1px solid rgba(197, 154, 68, 0.25);
    }
    .nav-inner {
      display: flex;
      justify-content: space-between;
      align-items: center;
      height: 74px;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text-main);
    }
    .logo-img {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      border: 1.5px solid var(--gold-secondary);
      object-fit: cover;
      box-shadow: 0 0 16px var(--gold-glow);
    }
    .logo-text {
      font-family: 'Playfair Display', serif;
      font-size: 23px;
      font-weight: 900;
      letter-spacing: 1.5px;
      background: linear-gradient(135deg, #FFFFFF 0%, #FFF6DF 40%, #FBBF24 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .nav-links {
      display: flex;
      align-items: center;
      gap: 24px;
      list-style: none;
    }
    .nav-links a {
      color: var(--text-muted);
      text-decoration: none;
      font-size: 14px;
      font-weight: 600;
      transition: color 0.2s;
    }
    .nav-links a:hover {
      color: var(--gold-primary);
    }
    .btn-nav-download {
      background: linear-gradient(135deg, #D97706 0%, #B45309 100%);
      color: #FFF;
      padding: 10px 22px;
      border-radius: 12px;
      font-weight: 700;
      font-size: 13.5px;
      text-decoration: none;
      border: 1px solid var(--gold-primary);
      box-shadow: 0 4px 16px rgba(217, 119, 6, 0.35);
      transition: all 0.25s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .btn-nav-download:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 22px rgba(251, 191, 36, 0.45);
    }

    /* Hero Section */
    .hero {
      padding: 70px 0 60px;
      position: relative;
    }
    .hero-grid {
      display: grid;
      grid-template-columns: 1.15fr 0.85fr;
      align-items: center;
      gap: 50px;
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
      margin-bottom: 22px;
    }
    .hero-title {
      font-family: 'Playfair Display', serif;
      font-size: clamp(34px, 4.4vw, 56px);
      font-weight: 900;
      line-height: 1.2;
      letter-spacing: 0.3px;
      margin-bottom: 20px;
      background: linear-gradient(135deg, #FFFFFF 0%, #FFF6DF 40%, #FBBF24 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .hero-subtitle {
      font-size: clamp(15px, 1.8vw, 17.5px);
      color: var(--text-muted);
      line-height: 1.7;
      margin-bottom: 34px;
    }
    .hero-subtitle strong {
      color: var(--text-main);
      font-weight: 600;
    }
    .hero-ctas {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
    }
    .btn-primary-hero {
      background: linear-gradient(135deg, #F59E0B 0%, #D97706 60%, #92400E 100%);
      color: #FFF;
      padding: 16px 32px;
      border-radius: 16px;
      font-size: 16px;
      font-weight: 800;
      text-decoration: none;
      border: 1.5px solid var(--gold-primary);
      box-shadow: 0 10px 30px rgba(245, 158, 11, 0.45);
      transition: all 0.3s ease;
      display: inline-flex;
      align-items: center;
      gap: 12px;
    }
    .btn-primary-hero:hover {
      transform: translateY(-3px) scale(1.02);
      box-shadow: 0 14px 40px rgba(251, 191, 36, 0.6);
    }
    .btn-secondary-hero {
      background: rgba(15, 29, 48, 0.7);
      color: var(--text-main);
      padding: 16px 26px;
      border-radius: 16px;
      font-size: 15px;
      font-weight: 700;
      text-decoration: none;
      border: 1.2px solid var(--gold-border);
      transition: all 0.3s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .btn-secondary-hero:hover {
      background: rgba(22, 45, 74, 0.9);
      border-color: var(--gold-secondary);
      transform: translateY(-2px);
    }
    .hero-badges {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      font-size: 12.5px;
      color: var(--text-dim);
    }
    .hero-badge-item {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: #94A3B8;
    }

    /* Phone Mockup Styling */
    .phone-container {
      position: relative;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .phone-mockup-frame {
      width: 290px;
      height: 590px;
      background: #0D1624;
      border-radius: 46px;
      padding: 10px;
      box-shadow: 
        0 24px 60px rgba(0, 0, 0, 0.85),
        0 0 0 2px #263852,
        0 0 0 5px #0E1A2B,
        0 0 35px var(--gold-glow);
      position: relative;
      transition: transform 0.4s ease, box-shadow 0.4s ease;
      cursor: pointer;
    }
    .phone-mockup-frame:hover {
      transform: translateY(-8px) rotate(-1deg);
      box-shadow: 
        0 30px 80px rgba(0, 0, 0, 0.95),
        0 0 0 2px var(--gold-secondary),
        0 0 0 5px #0E1A2B,
        0 0 50px rgba(251, 191, 36, 0.4);
    }
    .phone-screen {
      width: 100%;
      height: 100%;
      border-radius: 36px;
      overflow: hidden;
      background: #000;
      position: relative;
    }
    .phone-screen img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    .phone-notch {
      position: absolute;
      top: 14px;
      left: 50%;
      transform: translateX(-50%);
      width: 80px;
      height: 16px;
      background: #000;
      border-radius: 12px;
      z-index: 10;
    }
    .phone-glare {
      position: absolute;
      top: 0;
      right: 0;
      width: 100%;
      height: 100%;
      background: linear-gradient(135deg, rgba(255, 255, 255, 0.12) 0%, transparent 60%);
      pointer-events: none;
      border-radius: 36px;
    }

    /* Floating Chips around Hero Phone */
    .floating-chip {
      position: absolute;
      background: rgba(10, 24, 42, 0.88);
      border: 1.2px solid var(--gold-secondary);
      border-radius: 16px;
      padding: 10px 16px;
      backdrop-filter: blur(14px);
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.7);
      display: flex;
      align-items: center;
      gap: 10px;
      z-index: 20;
      animation: floatChip 5s ease-in-out infinite;
    }
    .chip-left {
      left: -30px;
      top: 15%;
    }
    .chip-right {
      right: -25px;
      bottom: 22%;
      animation-delay: -2.5s;
    }
    @keyframes floatChip {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-8px); }
    }
    .chip-icon {
      font-size: 20px;
    }
    .chip-title {
      font-size: 12.5px;
      font-weight: 700;
      color: #FFF;
      line-height: 1.2;
    }
    .chip-sub {
      font-size: 11px;
      color: var(--gold-secondary);
      margin-top: 2px;
    }

    /* Section Headers */
    .section-wrap {
      padding: 80px 0;
    }
    .section-header {
      text-align: center;
      max-width: 720px;
      margin: 0 auto 50px;
    }
    .section-tag {
      font-size: 12px;
      font-weight: 700;
      color: var(--gold-secondary);
      letter-spacing: 2.2px;
      text-transform: uppercase;
      margin-bottom: 10px;
      display: inline-block;
    }
    .section-title {
      font-family: 'Playfair Display', serif;
      font-size: clamp(28px, 3.6vw, 42px);
      font-weight: 900;
      color: #FFF;
      line-height: 1.25;
      margin-bottom: 14px;
    }
    .section-desc {
      font-size: 15.5px;
      color: var(--text-muted);
      line-height: 1.65;
    }

    /* 4-Screen Showcase Grid */
    .showcase-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 24px;
    }
    .showcase-card {
      background: var(--bg-card);
      border: 1.2px solid var(--gold-border);
      border-radius: 28px;
      padding: 20px;
      backdrop-filter: blur(14px);
      transition: all 0.35s ease;
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      position: relative;
      cursor: pointer;
    }
    .showcase-card:hover {
      transform: translateY(-8px);
      border-color: var(--gold-primary);
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.7), 0 0 25px var(--gold-glow);
    }
    .card-phone-mini {
      width: 100%;
      max-width: 220px;
      aspect-ratio: 9 / 18.5;
      background: #0A131F;
      border-radius: 24px;
      padding: 6px;
      border: 2px solid #1E314B;
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.6);
      margin-bottom: 18px;
      overflow: hidden;
      position: relative;
    }
    .card-phone-mini img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 18px;
      display: block;
      transition: transform 0.4s ease;
    }
    .showcase-card:hover .card-phone-mini img {
      transform: scale(1.04);
    }
    .card-badge {
      font-size: 10.5px;
      font-weight: 800;
      color: var(--gold-secondary);
      letter-spacing: 1.2px;
      text-transform: uppercase;
      margin-bottom: 6px;
    }
    .card-title {
      font-family: 'Playfair Display', serif;
      font-size: 18px;
      font-weight: 800;
      color: #FFF;
      margin-bottom: 8px;
      line-height: 1.3;
    }
    .card-desc {
      font-size: 13px;
      color: var(--text-muted);
      line-height: 1.5;
    }

    /* Core Features Matrix */
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(270px, 1fr));
      gap: 24px;
    }
    .feature-card {
      background: var(--bg-card);
      border: 1.2px solid var(--gold-border);
      border-radius: 24px;
      padding: 30px 26px;
      backdrop-filter: blur(12px);
      transition: all 0.3s ease;
    }
    .feature-card:hover {
      transform: translateY(-6px);
      border-color: var(--gold-primary);
      box-shadow: 0 16px 36px rgba(0, 0, 0, 0.6), 0 0 24px var(--gold-glow);
    }
    .feature-icon-box {
      width: 56px;
      height: 56px;
      border-radius: 16px;
      background: linear-gradient(135deg, rgba(245, 158, 11, 0.2) 0%, rgba(217, 119, 6, 0.05) 100%);
      border: 1.5px solid var(--gold-secondary);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 26px;
      margin-bottom: 20px;
    }
    .feature-name {
      font-family: 'Playfair Display', serif;
      font-size: 21px;
      font-weight: 700;
      color: #FFF6DF;
      margin-bottom: 12px;
    }
    .feature-text {
      font-size: 14px;
      color: var(--text-muted);
      line-height: 1.65;
    }

    /* Comparison Table Section */
    .comparison-card {
      background: var(--bg-card);
      border: 1.2px solid var(--gold-border);
      border-radius: 28px;
      overflow: hidden;
      backdrop-filter: blur(16px);
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
    }
    .comparison-table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    .comparison-table th {
      padding: 20px 24px;
      background: rgba(14, 28, 48, 0.85);
      border-bottom: 1.5px solid rgba(197, 154, 68, 0.35);
      font-size: 14.5px;
      font-weight: 700;
      color: #FFF;
    }
    .comparison-table th.highlight {
      background: linear-gradient(135deg, rgba(245, 158, 11, 0.25), rgba(180, 83, 9, 0.15));
      color: var(--gold-primary);
      font-family: 'Playfair Display', serif;
      font-size: 17px;
      font-weight: 800;
      border-left: 1.5px solid var(--gold-border);
      border-right: 1.5px solid var(--gold-border);
    }
    .comparison-table td {
      padding: 18px 24px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      font-size: 14px;
      color: var(--text-muted);
    }
    .comparison-table tr:hover td {
      background: rgba(255, 255, 255, 0.02);
    }
    .comparison-table td.highlight {
      background: rgba(245, 158, 11, 0.06);
      border-left: 1.5px solid var(--gold-border);
      border-right: 1.5px solid var(--gold-border);
      font-weight: 600;
      color: #FFF;
    }

    /* In-App Browser Alert Banner */
    .inapp-banner {
      display: none;
      background: linear-gradient(135deg, rgba(180, 83, 9, 0.95), rgba(146, 64, 14, 0.95));
      color: #FFF6DF;
      padding: 12px 20px;
      font-size: 13.5px;
      font-weight: 600;
      text-align: center;
      border-bottom: 1.5px solid var(--gold-primary);
      position: sticky;
      top: 0;
      z-index: 1002;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.6);
      line-height: 1.5;
    }
    .inapp-banner.active {
      display: block;
    }

    /* Download Box Hub (No QR, No Admin Upload) */
    .download-hub {
      background: linear-gradient(135deg, rgba(14, 28, 48, 0.95), rgba(7, 15, 28, 0.98));
      border: 1.5px solid var(--gold-primary);
      border-radius: 32px;
      padding: 56px 40px;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8), 0 0 35px var(--gold-glow);
      text-align: center;
      max-width: 860px;
      margin: 20px auto 0;
      position: relative;
      overflow: hidden;
    }
    .download-hub::before {
      content: '';
      position: absolute;
      top: -50%;
      left: -50%;
      width: 200%;
      height: 200%;
      background: radial-gradient(circle at center, rgba(251, 191, 36, 0.08) 0%, transparent 60%);
      pointer-events: none;
    }
    .download-hub-title {
      font-family: 'Playfair Display', serif;
      font-size: clamp(26px, 3.4vw, 38px);
      font-weight: 900;
      color: #FFF;
      margin-bottom: 16px;
      position: relative;
    }
    .download-hub-desc {
      font-size: 15.5px;
      color: var(--text-muted);
      line-height: 1.7;
      margin-bottom: 32px;
      max-width: 680px;
      margin-left: auto;
      margin-right: auto;
      position: relative;
    }
    .hub-actions {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      position: relative;
    }
    .hub-meta {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;
      gap: 16px;
      font-size: 12.5px;
      color: var(--text-dim);
      position: relative;
    }
    .hub-meta span {
      display: inline-flex;
      align-items: center;
      gap: 5px;
    }

    /* Download Feedback Toast */
    .download-toast {
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: rgba(10, 22, 38, 0.96);
      border: 1.5px solid var(--gold-primary);
      border-radius: 20px;
      padding: 18px 22px;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.85), 0 0 35px var(--gold-glow);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      z-index: 999;
      max-width: 440px;
      width: calc(100% - 48px);
      transform: translateY(140px);
      opacity: 0;
      pointer-events: none;
      transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .download-toast.show {
      transform: translateY(0);
      opacity: 1;
      pointer-events: auto;
    }
    .toast-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 8px;
    }
    .toast-title {
      font-weight: 800;
      font-size: 15px;
      color: var(--gold-primary);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .toast-close {
      cursor: pointer;
      color: var(--text-muted);
      font-size: 16px;
      padding: 2px 6px;
      border-radius: 6px;
      transition: color 0.2s;
    }
    .toast-close:hover {
      color: #FFF;
    }
    .toast-desc {
      font-size: 13px;
      color: var(--text-muted);
      line-height: 1.5;
    }
    .toast-link {
      color: var(--gold-secondary);
      font-size: 12.5px;
      font-weight: 700;
      text-decoration: underline;
      transition: color 0.2s;
    }
    .toast-link:hover {
      color: var(--gold-primary);
    }

    /* 3 Step Installation */
    .steps-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 26px;
      margin-top: 40px;
    }
    .step-card {
      background: var(--bg-card);
      border: 1px solid rgba(197, 154, 68, 0.35);
      border-radius: 22px;
      padding: 30px 24px;
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
      font-size: 17.5px;
      font-weight: 700;
      color: #FFF;
      margin: 8px 0 8px;
    }
    .step-desc {
      font-size: 13.5px;
      color: var(--text-muted);
      line-height: 1.6;
    }

    /* Modal Lightbox */
    .modal-lightbox {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.88);
      z-index: 1000;
      align-items: center;
      justify-content: center;
      padding: 20px;
      backdrop-filter: blur(10px);
    }
    .modal-lightbox.active {
      display: flex;
    }
    .modal-content {
      max-width: 420px;
      max-height: 90vh;
      border-radius: 36px;
      overflow: hidden;
      box-shadow: 0 0 50px rgba(251, 191, 36, 0.35);
      border: 2px solid var(--gold-secondary);
      position: relative;
    }
    .modal-content img {
      width: 100%;
      height: auto;
      display: block;
    }
    .modal-close {
      position: absolute;
      top: 16px;
      right: 16px;
      width: 36px;
      height: 36px;
      background: rgba(0, 0, 0, 0.75);
      border: 1px solid var(--gold-secondary);
      color: #FFF;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 18px;
      font-weight: bold;
    }

    /* Footer */
    footer {
      padding: 60px 0 40px;
      text-align: center;
      border-top: 1px solid rgba(197, 154, 68, 0.2);
      color: var(--text-dim);
      font-size: 13.5px;
    }
    footer a {
      color: var(--gold-secondary);
      text-decoration: none;
    }
    footer a:hover {
      text-decoration: underline;
    }

    /* Responsive */
    @media (max-width: 1024px) {
      .showcase-grid {
        grid-template-columns: repeat(2, 1fr);
      }
      .hero-grid {
        grid-template-columns: 1fr;
        text-align: center;
        gap: 40px;
      }
      .hero-ctas, .hero-badges {
        justify-content: center;
      }
      .chip-left { left: 5%; }
      .chip-right { right: 5%; }
    }
    @media (max-width: 640px) {
      .showcase-grid {
        grid-template-columns: 1fr;
      }
      .nav-links {
        display: none;
      }
      .hero {
        padding: 40px 0 30px;
      }
      .btn-primary-hero {
        width: 100%;
        justify-content: center;
      }
      .btn-secondary-hero {
        width: 100%;
        justify-content: center;
      }
      .floating-chip {
        display: none;
      }
      .phone-mockup-frame {
        width: 260px;
        height: 530px;
      }
    }
  </style>
</head>
<body>

  <!-- In-App Browser Warning Banner (Zalo, Facebook Messenger, etc.) -->
  <div class="inapp-banner" id="inappBanner">
    ⚠️ Bạn đang mở trang web trong ứng dụng (Zalo / Facebook). Vui lòng nhấn biểu tượng dấu 3 chấm <strong>⋮</strong> ở góc trên và chọn <strong>"Mở bằng trình duyệt ngoài"</strong> (Chrome / Cốc Cốc) để tải tệp APK!
  </div>

  <!-- Navigation -->
  <nav>
    <div class="container nav-inner">
      <a href="/" class="logo">
        <img src="/logo.png" alt="Tiên Lộ" class="logo-img">
        <div class="logo-text">TIÊN LỘ</div>
      </a>
      <ul class="nav-links">
        <li><a href="#showcase">Giao Diện App</a></li>
        <li><a href="#features">Hệ Thống Solo Leveling</a></li>
        <li><a href="#comparison">So Sánh Đột Phá</a></li>
        <li><a href="#guide">Hướng Dẫn Cài Đặt</a></li>
      </ul>
      <div class="nav-actions">
        <a href="${downloadUrl}" class="btn-nav-download" id="nav-download-btn" download="TienLo-release.apk" onclick="handleDownload(event, '${downloadUrl}', '${githubReleaseUrl}')">
          <span>⬇ Tải APK (v${latestVersion})</span>
        </a>
      </div>
    </div>
  </nav>

  <!-- Hero Section -->
  <section class="hero">
    <div class="container hero-grid">
      <div class="hero-content">
        <div class="hero-tag">
          <span>✨ GAMIFIED HABIT &amp; SELF-IMPROVEMENT APP</span>
        </div>
        <h1 class="hero-title">
          KỶ LUẬT THÀNH ĐẠO<br>
          THĂNG CẤP BẢN THÂN
        </h1>
        <p class="hero-subtitle">
          Biến từng giọt mồ hôi khi <strong>chống đẩy, chạy bộ</strong> và từng giờ <strong>tập trung làm việc</strong> thành luồng Linh Lực tu chân. Đột phá <strong>10 Đại Cảnh Giới</strong> từ Phàm Nhân đến Phi Thăng, rèn ý chí thép như <strong>Thợ Săn Sung Jin-woo</strong> cùng sự dẫn dắt của <strong>Thiên Đạo AI</strong>.
        </p>

        <div class="hero-ctas">
          <a href="${downloadUrl}" class="btn-primary-hero" id="hero-download-btn" download="TienLo-release.apk" onclick="handleDownload(event, '${downloadUrl}', '${githubReleaseUrl}')">
            <span style="font-size: 20px;">⚡</span>
            <span>TẢI BẢN APK NGAY (v${latestVersion})</span>
          </a>
          <a href="#showcase" class="btn-secondary-hero">
            <span>📱 Khám Phá Giao Diện</span>
            <span>↓</span>
          </a>
        </div>

        <div class="hero-badges">
          <div class="hero-badge-item"><span>📱</span> <span>Android 7.0+</span></div>
          <div class="hero-badge-item"><span>🔄</span> <span>Tự động cập nhật OTA</span></div>
          <div class="hero-badge-item"><span>🤖</span> <span>Gemini AI Siêu Tốc</span></div>
          <div class="hero-badge-item"><span>🛡️</span> <span>Bảo mật & Không quảng cáo</span></div>
        </div>
      </div>

      <!-- Hero Phone Showcase with Real App Screenshot -->
      <div class="phone-container">
        <!-- Floating Chip 1 -->
        <div class="floating-chip chip-left">
          <div class="chip-icon">🏋️‍♂️</div>
          <div>
            <div class="chip-title">Daily Quest Solo Leveling</div>
            <div class="chip-sub">Chống đẩy • Chạy bộ • Thiền</div>
          </div>
        </div>

        <!-- Phone Mockup Frame -->
        <div class="phone-mockup-frame" onclick="openLightbox('/screenshots/screen_home.jpg')">
          <div class="phone-notch"></div>
          <div class="phone-glare"></div>
          <div class="phone-screen">
            <img src="/screenshots/screen_home.jpg" alt="Màn hình chính Tiên Lộ">
          </div>
        </div>

        <!-- Floating Chip 2 -->
        <div class="floating-chip chip-right">
          <div class="chip-icon">⚡</div>
          <div>
            <div class="chip-title">10 Cảnh Giới Tu Tiên</div>
            <div class="chip-sub">Phàm Nhân ➔ Phi Thăng</div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- 4-Screen Showcase Gallery -->
  <section class="section-wrap" id="showcase">
    <div class="container">
      <div class="section-header">
        <div class="section-tag">CHIÊM NGƯỠNG GIAO DIỆN</div>
        <h2 class="section-title">4 Đại Pháp Môn Trong Ứng Dụng</h2>
        <p class="section-desc">
          Thiết kế đồ họa huyền ảo sang trọng, tối ưu tỉ mỉ từng chỉ số và tương tác mang lại trải nghiệm tu chân đắm chìm mỗi ngày.
        </p>
      </div>

      <div class="showcase-grid">
        <!-- Card 1 -->
        <div class="showcase-card" onclick="openLightbox('/screenshots/screen_home.jpg')">
          <div class="card-phone-mini">
            <img src="/screenshots/screen_home.jpg" alt="Tu Luyện Mỗi Ngày">
          </div>
          <div class="card-badge">Chương I • Trang Chủ</div>
          <h3 class="card-title">Tu Luyện Mỗi Ngày</h3>
          <p class="card-desc">
            Nhiệm vụ rèn luyện thể chất Solo Leveling, tích lũy Linh Lực và ô triệu hồi Thiên Đạo AI diễn toán mục tiêu.
          </p>
        </div>

        <!-- Card 2 -->
        <div class="showcase-card" onclick="openLightbox('/screenshots/screen_stats.jpg')">
          <div class="card-phone-mini">
            <img src="/screenshots/screen_stats.jpg" alt="Bản Đồ Chiến Dịch & Kỹ Năng">
          </div>
          <div class="card-badge">Skill Tree • Thống Kê</div>
          <h3 class="card-title">Căn Cốt Đời Thực</h3>
          <p class="card-desc">
            4 Thuộc tính cốt lõi: Thể chất, Trí thức, Tập trung, Giao tiếp cùng biểu đồ nhịp độ 7 ngày trực quan.
          </p>
        </div>

        <!-- Card 3 -->
        <div class="showcase-card" onclick="openLightbox('/screenshots/screen_profile.jpg')">
          <div class="card-phone-mini">
            <img src="/screenshots/screen_profile.jpg" alt="Hồ Sơ Tu Luyện">
          </div>
          <div class="card-badge">Đạo Hữu • Cá Nhân</div>
          <h3 class="card-title">Hồ Sơ Tu Sĩ</h3>
          <p class="card-desc">
            Theo dõi Chuỗi ngày kỷ luật (Streak), Tổng linh lực, số lượng Nguyên Thạch và cảnh giới Luyện Khí hiện tại.
          </p>
        </div>

        <!-- Card 4 -->
        <div class="showcase-card" onclick="openLightbox('/screenshots/screen_realms.jpg')">
          <div class="card-phone-mini">
            <img src="/screenshots/screen_realms.jpg" alt="10 Đại Cảnh Giới">
          </div>
          <div class="card-badge">Đại Lộ Thăng Thiên</div>
          <h3 class="card-title">10 Đại Cảnh Giới</h3>
          <p class="card-desc">
            Lộ trình thăng tiến từ Phàm Nhân, Luyện Khí, Kết Đan, Nguyên Anh tới Hóa Thần, Đại Thừa và Phi Thăng Thần Giới.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- Core Features Matrix -->
  <section class="section-wrap" id="features" style="background: rgba(10, 22, 38, 0.45); border-top: 1px solid rgba(197, 154, 68, 0.2); border-bottom: 1px solid rgba(197, 154, 68, 0.2);">
    <div class="container">
      <div class="section-header">
        <div class="section-tag">HỆ THỐNG CỐT LÕI</div>
        <h2 class="section-title">Tại Sao Tiên Lộ Lại Giúp Bạn Kỷ Luật Hơn?</h2>
        <p class="section-desc">
          Kết hợp hoàn hảo giữa tâm lý học hành vi, cơ chế gamification nhập vai cuốn hút và sự nghiêm khắc của Hệ Thống Solo Leveling.
        </p>
      </div>

      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon-box">⚔️</div>
          <h3 class="feature-name">Solo Leveling Quests</h3>
          <p class="feature-text">
            Nhiệm vụ rõ ràng với động tác và con số cụ thể (VD: Chống đẩy 50 cái, Chạy bộ 3km). Không hoàn thành trong ngày sẽ nhận hình phạt trừ Linh Lực!
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">🤖</div>
          <h3 class="feature-name">Thiên Đạo AI (Gemini)</h3>
          <p class="feature-text">
            Chỉ cần nhập bất kỳ mục tiêu đời thực nào, Thiên Đạo AI sẽ tự động phân tích và tạo ra chiến dịch tu chân 14-30 ngày với độ khó tăng dần.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">🌳</div>
          <h3 class="feature-name">Real-Life Skill Tree</h3>
          <p class="feature-text">
            Điểm số và chỉ số không phải ảo. Mọi thành tựu tu luyện đều phản ánh trực tiếp sự phát triển thể chất và trí tuệ thật sự của bạn ngoài đời thực.
          </p>
        </div>

        <div class="feature-card">
          <div class="feature-icon-box">🔄</div>
          <h3 class="feature-name">Tự Động Cập Nhật OTA</h3>
          <p class="feature-text">
            Không cần phụ thuộc CH Play. Ứng dụng tự động phát hiện bản phát hành mới và cài đặt trực tiếp chỉ với một chạm ngay trong app.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- Comparison Table -->
  <section class="section-wrap" id="comparison">
    <div class="container">
      <div class="section-header">
        <div class="section-tag">SO SÁNH ĐỘT PHÁ</div>
        <h2 class="section-title">Sự Khác Biệt Giữa Tiên Lộ & App Khác</h2>
      </div>

      <div class="comparison-card">
        <table class="comparison-table">
          <thead>
            <tr>
              <th style="width: 32%;">Tiêu Chí</th>
              <th style="width: 34%;">App Theo Dõi Thông Thường</th>
              <th class="highlight" style="width: 34%;">Ứng Dụng Tiên Lộ ⚡</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td><strong>Cơ chế thúc đẩy</strong></td>
              <td>Tích dấu tick đơn điệu, dễ nhàm chán</td>
              <td class="highlight">Hệ thống Tu Tiên Solo Leveling, tích lũy EXP đột phá cảnh giới</td>
            </tr>
            <tr>
              <td><strong>Tính kỷ luật</strong></td>
              <td>Bỏ qua không sao, không có trách nhiệm</td>
              <td class="highlight">Có cơ chế hình phạt nghiêm khắc trừ Linh Lực nếu trốn tránh</td>
            </tr>
            <tr>
              <td><strong>Tạo lộ trình</strong></td>
              <td>Tự gõ checklist thủ công từ đầu đến cuối</td>
              <td class="highlight">Thiên Đạo AI tự động diễn toán lộ trình 14-30 ngày phù hợp</td>
            </tr>
            <tr>
              <td><strong>Chỉ số phát triển</strong></td>
              <td>Biểu đồ cột khô khan, thiếu cảm hứng</td>
              <td class="highlight">Cây kỹ năng 4 nhánh Thể chất - Trí thức - Tập trung - Giao tiếp</td>
            </tr>
            <tr>
              <td><strong>Cập nhật phiên bản</strong></td>
              <td>Phải tìm tải file APK mới thủ công</td>
              <td class="highlight">Tự động kiểm tra và nâng cấp phiên bản OTA 1 chạm trong app</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </section>

  <!-- Download Hub (No QR & No Admin Upload) -->
  <section class="section-wrap" id="guide">
    <div class="container">
      <div class="download-hub">
        <div class="hero-tag" style="margin-bottom: 16px;">
          <span>🚀 BẢN PHÁT HÀNH CHÍNH THỨC • V${latestVersion}</span>
        </div>
        <h2 class="download-hub-title">Sẵn Sàng Bước Vào Con Đường Kỷ Luật?</h2>
        <p class="download-hub-desc">
          Tải ngay tệp cài đặt <strong>TienLo-release.apk (v${latestVersion})</strong> hoàn toàn miễn phí. Bắt đầu hành trình tôi luyện thể phách và thức tỉnh sức mạnh từ hôm nay.
        </p>
        
        <div class="hub-actions">
          <a href="${downloadUrl}" class="btn-primary-hero" id="hub-download-btn" download="TienLo-release.apk" onclick="handleDownload(event, '${downloadUrl}', '${githubReleaseUrl}')">
            <span style="font-size: 20px;">⬇</span>
            <span>TẢI TIÊN LỘ APK (v${latestVersion})</span>
          </a>
          <a href="${githubReleaseUrl}" target="_blank" rel="noopener noreferrer" class="btn-secondary-hero" id="hub-github-btn">
            <span>🐙 Tải Từ GitHub Release (Dự phòng)</span>
            <span>↗</span>
          </a>
        </div>

        <div class="hub-meta">
          <span>📦 Dung lượng: ~58 MB</span>
          <span>•</span>
          <span>📱 Android 7.0+</span>
          <span>•</span>
          <span>⚡ Tự động cập nhật OTA</span>
          <span>•</span>
          <span>🛡️ An toàn &amp; Không quảng cáo</span>
        </div>
      </div>

      <!-- 3 Steps Installation -->
      <div class="steps-grid">
        <div class="step-card">
          <div class="step-num">1</div>
          <h4 class="step-title">Tải Tệp APK</h4>
          <p class="step-desc">
            Bấm nút Tải APK ở trên để tải trực tiếp file <code>TienLo-release.apk</code> về máy Android của bạn.
          </p>
        </div>

        <div class="step-card">
          <div class="step-num">2</div>
          <h4 class="step-title">Cho Phép Cài Đặt</h4>
          <p class="step-desc">
            Nhấn mở file APK vừa tải. Nếu Android hiển thị thông báo bảo mật nguồn ngoài, hãy chọn "Cài đặt từ nguồn này" ➔ Cho phép.
          </p>
        </div>

        <div class="step-card">
          <div class="step-num">3</div>
          <h4 class="step-title">Tự Động Cập Nhật OTA</h4>
          <p class="step-desc">
            Mở ứng dụng và bắt đầu tu luyện! Các bản cập nhật sau này sẽ được thông báo và nâng cấp trực tiếp ngay trong app.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- Modal Lightbox for Image Zoom -->
  <div class="modal-lightbox" id="imageModal" onclick="closeLightbox()">
    <div class="modal-content" onclick="event.stopPropagation()">
      <div class="modal-close" onclick="closeLightbox()">✕</div>
      <img id="modalImg" src="" alt="Chi tiết màn hình">
    </div>
  </div>

  <!-- Download Feedback Toast -->
  <div class="download-toast" id="downloadToast">
    <div class="toast-header">
      <div class="toast-title">
        <span>⚡ Đang Bắt Đầu Tải Xuống...</span>
      </div>
      <div class="toast-close" onclick="closeToast()">✕</div>
    </div>
    <div class="toast-desc">
      Trình duyệt đang tải tệp <strong>TienLo-release.apk (v${latestVersion})</strong>. Nếu thấy cảnh báo <em>"Tệp có thể gây hại"</em>, hãy chọn <strong>"Vẫn tải xuống"</strong>.
    </div>
    <div style="margin-top: 10px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;">
      <a href="${githubReleaseUrl}" target="_blank" rel="noopener noreferrer" class="toast-link">
        👉 Bấm vào đây nếu chưa tải được (Link Dự Phòng GitHub)
      </a>
      <span style="font-size: 11.5px; color: var(--gold-secondary);">~58 MB</span>
    </div>
  </div>

  <!-- Footer -->
  <footer>
    <div class="container">
      <div style="margin-bottom: 14px;">
        <img src="/logo.png" alt="Tiên Lộ Logo" style="width: 40px; height: 40px; border-radius: 10px; border: 1px solid var(--gold-secondary); vertical-align: middle; margin-right: 8px;">
        <span style="font-family: 'Playfair Display', serif; font-size: 20px; font-weight: 900; color: #FFF; vertical-align: middle;">TIÊN LỘ</span>
      </div>
      <p style="margin-bottom: 8px;">
        Hệ thống phát triển bản thân &amp; Thói quen kỷ luật theo phong cách Tu Tiên Huyền Huyễn &amp; Solo Leveling.
      </p>
      <p>
        Phát triển bởi <a href="https://github.com/ManhNgoDev/TienLo" target="_blank" rel="noopener">ManhNgoDev</a> • Phiên bản v${latestVersion} • Vận hành trên Render Cloud
      </p>
    </div>
  </footer>

  <script>
    function openLightbox(src) {
      const modal = document.getElementById('imageModal');
      const modalImg = document.getElementById('modalImg');
      modalImg.src = src;
      modal.classList.add('active');
    }

    function closeLightbox() {
      const modal = document.getElementById('imageModal');
      modal.classList.remove('active');
    }

    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        closeLightbox();
      }
    });

    function handleDownload(event, primaryUrl, fallbackUrl) {
      const toast = document.getElementById('downloadToast');
      if (toast) {
        toast.classList.add('show');
      }

      // Explicitly trigger download link
      setTimeout(function() {
        const link = document.createElement('a');
        link.href = primaryUrl;
        link.setAttribute('download', 'TienLo-release.apk');
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }, 100);
    }

    function closeToast() {
      const toast = document.getElementById('downloadToast');
      if (toast) {
        toast.classList.remove('show');
      }
    }

    // In-app browser detection (Zalo, Facebook, Messenger)
    (function detectInAppBrowser() {
      const ua = navigator.userAgent || navigator.vendor || window.opera || '';
      const isInApp = /FBAN|FBAV|Zalo|Line|Instagram|MicroMessenger/i.test(ua);
      if (isInApp) {
        const banner = document.getElementById('inappBanner');
        if (banner) {
          banner.classList.add('active');
        }
      }
    })();
  </script>

</body>
</html>`;
}
