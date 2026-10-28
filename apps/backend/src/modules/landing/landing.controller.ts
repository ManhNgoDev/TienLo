import {
  Controller,
  Get,
  Header,
  Res,
  Param,
} from '@nestjs/common';
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
      res.setHeader('Content-Disposition', 'attachment; filename="TienLo-release.apk"');
      return res.download(localApk, 'TienLo-release.apk');
    }
    const versionInfo = await this.appService.getAppVersion();
    const downloadUrl =
      versionInfo.downloadUrl ||
      'https://github.com/ManhNgoDev/TienLo/releases/latest/download/TienLo-release.apk';
    res.setHeader('Content-Disposition', 'attachment; filename="TienLo-release.apk"');
    return res.redirect(downloadUrl);
  }

  @Get('download/apk')
  async downloadApkDirect(@Res() res: ExpressResponse) {
    return this.downloadApk(res);
  }

  @Get()
  @Header('Content-Type', 'text/html; charset=utf-8')
  async getLandingPage(): Promise<string> {
    const versionInfo = await this.appService.getAppVersion();
    const latestVersion = versionInfo.latestVersion || '1.1.2';
    const downloadUrl = '/download';
    const githubReleaseUrl =
      versionInfo.downloadUrl ||
      'https://github.com/ManhNgoDev/TienLo/releases/latest';

    return getLandingHtml(latestVersion, downloadUrl, githubReleaseUrl);
  }
}
