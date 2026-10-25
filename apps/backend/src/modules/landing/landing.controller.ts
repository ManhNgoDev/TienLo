import {
  Controller,
  Get,
  Post,
  Header,
  Res,
  Body,
  Param,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { AppService } from '../../app.service.js';
import { getLandingHtml } from './landing-page.template.js';

interface ExpressResponse {
  setHeader(name: string, value: string): this;
  status(code: number): this;
  send(body: any): any;
  json(body: any): any;
  redirect(url: string): any;
  download(path: string, filename?: string): void;
  [key: string]: any;
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

@Controller()
export class LandingController {
  constructor(private readonly appService: AppService) {}

  private getLocalApkPath(): string | null {
    const candidates = [
      path.resolve(process.cwd(), 'apps/backend/public/downloads/TienLo-release.apk'),
      path.resolve(process.cwd(), 'apps/backend/public/downloads/TienLo.apk'),
      path.resolve(process.cwd(), 'public/downloads/TienLo-release.apk'),
      path.resolve(process.cwd(), 'public/downloads/TienLo.apk'),
      path.resolve(process.cwd(), 'dist/public/downloads/TienLo-release.apk'),
      path.resolve(process.cwd(), 'apps/backend/dist/public/downloads/TienLo-release.apk'),
    ];

    for (const p of candidates) {
      if (fs.existsSync(p)) {
        return p;
      }
    }
    return null;
  }

  @Get('logo.png')
  getLogo(@Res() res: any) {
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

  @Get('favicon.ico')
  getFavicon(@Res() res: any) {
    return this.getLogo(res);
  }

  @Get('screenshots/:name')
  getScreenshot(@Param('name') name: string, @Res() res: any) {
    const safeName = path.basename(name);
    const candidates = [
      path.resolve(process.cwd(), `apps/backend/public/screenshots/${safeName}`),
      path.resolve(process.cwd(), `public/screenshots/${safeName}`),
      path.resolve(process.cwd(), `dist/public/screenshots/${safeName}`),
      path.resolve(process.cwd(), `apps/backend/dist/public/screenshots/${safeName}`),
      path.join(__dirname, 'screenshots', safeName),
    ];

    for (const p of candidates) {
      if (fs.existsSync(p)) {
        res.setHeader('Content-Type', 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return fs.createReadStream(p).pipe(res);
      }
    }
    return res.status(404).send('Screenshot not found');
  }

  @Get('download')
  async downloadApk(@Res() res: ExpressResponse) {
    const localApk = this.getLocalApkPath();
    if (localApk) {
      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      return res.download(localApk, 'TienLo-release.apk');
    }
    const versionInfo = await this.appService.getAppVersion();
    return res.redirect(versionInfo.downloadUrl);
  }

  @Get('download/apk')
  async downloadApkDirect(@Res() res: ExpressResponse) {
    const localApk = this.getLocalApkPath();
    if (localApk) {
      res.setHeader('Content-Type', 'application/vnd.android.package-archive');
      return res.download(localApk, 'TienLo-release.apk');
    }
    const versionInfo = await this.appService.getAppVersion();
    return res.redirect(versionInfo.downloadUrl);
  }

  @Get('admin/upload')
  @Header('Content-Type', 'text/html; charset=utf-8')
  getUploadPage(): string {
    return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Tiên Lộ • Quản Trị Tải Lên APK</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="icon" type="image/png" href="/logo.png">
  <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@700&family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    body { background: #060D17; color: #FFF6DF; font-family: 'Plus Jakarta Sans', sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; margin: 0; }
    .card { background: #0C1929; border: 1.5px solid #C59A44; border-radius: 24px; padding: 32px; max-width: 480px; width: 100%; box-shadow: 0 10px 40px rgba(0,0,0,0.8); }
    h1 { font-family: 'Cinzel', serif; font-size: 20px; color: #FBBF24; text-align: center; margin-bottom: 20px; }
    label { display: block; font-size: 13px; color: #8BA5BA; margin-bottom: 6px; font-weight: 600; }
    input, textarea { width: 100%; box-sizing: border-box; padding: 12px 14px; background: #08121E; border: 1px solid #334E68; border-radius: 12px; color: #FFF; font-size: 14px; margin-bottom: 16px; outline: none; }
    input:focus, textarea:focus { border-color: #FBBF24; }
    .btn { width: 100%; padding: 14px; background: linear-gradient(135deg, #F59E0B, #D97706); color: #FFF; border: none; border-radius: 14px; font-weight: bold; font-size: 15px; cursor: pointer; transition: 0.2s; }
    .btn:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(245,158,11,0.4); }
    .alert { padding: 12px; border-radius: 12px; font-size: 13px; margin-bottom: 16px; display: none; }
    .alert-success { background: rgba(16, 185, 129, 0.15); border: 1px solid #10B981; color: #6EE7B7; }
    .alert-error { background: rgba(239, 68, 68, 0.15); border: 1px solid #EF4444; color: #FCA5A5; }
  </style>
</head>
<body>
  <div class="card">
    <div style="text-align: center; margin-bottom: 12px;">
      <img src="/logo.png" style="width: 64px; height: 64px; border-radius: 16px; border: 1.5px solid #FBBF24; object-fit: cover;" alt="Logo">
    </div>
    <h1>ĐẨY BẢN CẬP NHẬT APK</h1>
    <div id="alert" class="alert"></div>
    <form id="uploadForm" enctype="multipart/form-data">
      <label>Chọn tệp APK phát hành (.apk):</label>
      <input type="file" name="apkFile" accept=".apk" required>

      <label>Phiên bản (ví dụ: 1.0.1):</label>
      <input type="text" name="version" placeholder="1.0.1" required>

      <label>Ghi chú bản cập nhật:</label>
      <textarea name="releaseNotes" rows="3" placeholder="• Sửa lỗi tu vi...&#10;• Bổ sung tính năng mới..."></textarea>

      <label>Mã bảo mật quản trị (Secret Key):</label>
      <input type="password" name="secretKey" placeholder="Nhập mã bảo mật (mặc định: tienlo2026)..." required>

      <button type="submit" class="btn" id="submitBtn">Tải Lên Máy Chủ Render</button>
    </form>
    <div style="text-align: center; margin-top: 18px;">
      <a href="/" style="color: #8BA5BA; font-size: 12.5px; text-decoration: none;">← Quay lại Trang Chủ Tiên Lộ</a>
    </div>
  </div>
  <script>
    const form = document.getElementById('uploadForm');
    const alertBox = document.getElementById('alert');
    const submitBtn = document.getElementById('submitBtn');

    form.onsubmit = async (e) => {
      e.preventDefault();
      alertBox.style.display = 'none';
      submitBtn.disabled = true;
      submitBtn.innerText = 'Đang tải lên và xử lý...';

      const formData = new FormData(form);
      try {
        const res = await fetch('/admin/upload', {
          method: 'POST',
          body: formData
        });
        const data = await res.json();
        if (res.ok) {
          alertBox.className = 'alert alert-success';
          alertBox.innerHTML = 'Thành công! Đã lưu bản APK v' + data.version + '. <br><a href="/download" style="color:#FFF; font-weight:bold;">Bấm vào đây để tải thử nghiệm</a>';
          alertBox.style.display = 'block';
          form.reset();
        } else {
          alertBox.className = 'alert alert-error';
          alertBox.innerText = data.message || 'Lỗi tải lên tệp.';
          alertBox.style.display = 'block';
        }
      } catch (err) {
        alertBox.className = 'alert alert-error';
        alertBox.innerText = 'Lỗi kết nối: ' + err.message;
        alertBox.style.display = 'block';
      } finally {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Tải Lên Máy Chủ Render';
      }
    };
  </script>
</body>
</html>`;
  }

  @Post('admin/upload')
  @UseInterceptors(FileInterceptor('apkFile'))
  async handleUpload(
    @UploadedFile() file: any,
    @Body() body: any,
    @Res() res: ExpressResponse,
  ) {
    const expectedSecret = process.env.ADMIN_KEY || 'tienlo2026';
    if (body.secretKey !== expectedSecret) {
      return res.status(403).json({ message: 'Mã bảo mật quản trị không chính xác!' });
    }

    if (!file || !file.buffer) {
      return res.status(400).json({ message: 'Vui lòng đính kèm tệp APK hợp lệ!' });
    }

    const version = (body.version || '1.0.1').trim().replace(/^v/, '');
    const releaseNotes = body.releaseNotes || 'Bản cập nhật tối ưu hóa và sửa lỗi.';

    const downloadDir = path.resolve(process.cwd(), 'apps/backend/public/downloads');
    if (!fs.existsSync(downloadDir)) {
      fs.mkdirSync(downloadDir, { recursive: true });
    }

    const targetFile = path.join(downloadDir, 'TienLo-release.apk');
    fs.writeFileSync(targetFile, file.buffer);

    // Lưu version info cục bộ để API trả về ngay
    const versionJsonPath = path.join(downloadDir, 'version.json');
    const versionData = {
      latestVersion: version,
      latestBuildNumber: 2,
      minSupportedVersion: '1.0.0',
      downloadUrl: '/download',
      releaseNotes,
      publishedAt: new Date().toISOString(),
      forceUpdate: false,
    };
    fs.writeFileSync(versionJsonPath, JSON.stringify(versionData, null, 2));

    return res.status(200).json({
      success: true,
      message: 'Tải lên và cập nhật bản APK thành công!',
      version,
      sizeBytes: file.size,
    });
  }

  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  async getLandingPage(): Promise<string> {
    const versionInfo = await this.appService.getAppVersion();
    const latestVersion = versionInfo.latestVersion || '1.0.2';
    const downloadUrl = versionInfo.downloadUrl || '/download';

    return getLandingHtml(latestVersion, downloadUrl);
  }
}
