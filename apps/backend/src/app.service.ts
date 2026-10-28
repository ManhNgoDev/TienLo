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

    let latestVersion = '1.0.5';
    let releaseNotes =
      '• Nâng số nhiệm vụ hàng ngày mặc định lên 5 nhiệm vụ có con số đo đếm/rep cụ thể\n• Khai mở tính năng Khai Mở Thêm Nhiệm Vụ (AI Gen Thêm) khi muốn rèn luyện bứt phá\n• Tích hợp hệ thống báo lỗi tự động gửi thông báo trực tiếp đến Gmail nhà phát triển\n• Sửa lỗi cập nhật ứng dụng tự động mở trình cài đặt APK không bị văng/crash\n• Đồng bộ chuỗi ngày tu luyện chuẩn xác khi hoàn thành toàn bộ nhiệm vụ\n• Bảng Xếp Hạng kết nối API trực tiếp từ máy chủ';
    let publishedAt = new Date().toISOString();
    let downloadUrl = `https://github.com/${owner}/${repo}/releases/download/v1.0.5/TienLo-release.apk`;

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
      latestBuildNumber: 4,
      minSupportedVersion: '1.0.0',
      downloadUrl,
      releaseNotes,
      publishedAt,
      forceUpdate: false,
    };
  }
}

