import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Hello World!';
  }

  getHealth() {
    return {
      status: 'ok',
      message: 'TienLo NestJS Backend is up and running!',
      service: 'tienlo-backend',
      timestamp: new Date().toISOString(),
    };
  }

  async getAppVersion() {
    // 1. Kiểm tra nếu có version.json lưu trữ cục bộ từ tệp upload
    const localCandidates = [
      path.resolve(process.cwd(), 'apps/backend/public/downloads/version.json'),
      path.resolve(process.cwd(), 'public/downloads/version.json'),
      path.resolve(process.cwd(), 'dist/public/downloads/version.json'),
      path.resolve(process.cwd(), 'apps/backend/dist/public/downloads/version.json'),
    ];
    for (const c of localCandidates) {
      if (fs.existsSync(c)) {
        try {
          const raw = fs.readFileSync(c, 'utf-8');
          const parsed = JSON.parse(raw);
          if (parsed && parsed.latestVersion) {
            return parsed;
          }
        } catch (_) {}
      }
    }

    const owner = process.env.GITHUB_OWNER || 'ManhNgoDev';
    const repo = process.env.GITHUB_REPO || 'TienLo';
    const defaultDownloadUrl = `https://github.com/${owner}/${repo}/releases/latest/download/TienLo-release.apk`;

    let latestVersion = '1.1.2';
    let releaseNotes =
      '🌐 Link tải thủ công qua Web (nếu máy bản cũ lỗi tự cập nhật):\n👉 https://tienlo.onrender.com\n📥 Tải thẳng APK: https://tienlo.onrender.com/download\n────────────────────\n• Bảo Toàn Session Đăng Xuất / Đăng Nhập: Khắc phục triệt để lỗi mất chiến dịch và nhiệm vụ hàng ngày khi đăng xuất rồi đăng nhập lại\n• Tổng Nhiệm Vụ Hồ Sơ Cá Nhân: Ghi nhận chính xác tổng số nhiệm vụ tích lũy đã hoàn thành\n• Chuỗi Ngày & Khóa Chiến Dịch: Mỗi ngày chỉ cộng tối đa +1 chuỗi ngày và khóa tạo chiến dịch mới cho đến khi hết số ngày mục tiêu';
    let publishedAt = new Date().toISOString();
    let downloadUrl = `https://github.com/${owner}/${repo}/releases/download/v1.1.2/TienLo-release.apk`;

    try {
      const res = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/releases/latest`,
        {
          headers: {
            'User-Agent': 'TienLo-App-Backend',
            Accept: 'application/vnd.github.v3+json',
          },
        },
      );

      if (res.ok) {
        const data: any = await res.json();
        if (data.tag_name) {
          latestVersion = data.tag_name.replace(/^v/, '');
        }
        if (data.body) {
          releaseNotes = data.body;
        }
        if (data.published_at) {
          publishedAt = data.published_at;
        }
        const apkAsset = Array.isArray(data.assets)
          ? data.assets.find((a: any) => a.name?.endsWith('.apk'))
          : null;
        if (apkAsset?.browser_download_url) {
          downloadUrl = apkAsset.browser_download_url;
        }
      }
    } catch (_) {}

    return {
      latestVersion,
      latestBuildNumber: 13,
      minSupportedVersion: '1.0.0',
      downloadUrl,
      releaseNotes,
      publishedAt,
      forceUpdate: false,
    };
  }
}

