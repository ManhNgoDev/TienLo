import { describe, it, expect, beforeEach } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(appController.getHello()).toBe('Hello World!');
    });

    it('should return app version info', async () => {
      const versionInfo = await appController.getAppVersion();
      expect(versionInfo).toBeDefined();
      expect(versionInfo.latestVersion).toBeDefined();
      expect(versionInfo.downloadUrl).toContain('.apk');
    });
  });
});
