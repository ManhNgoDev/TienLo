import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { ExpressAdapter, type NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(
    AppModule,
    new ExpressAdapter(),
  );

  app.enableCors();
  app.setGlobalPrefix('api', {
    exclude: [
      '/',
      'favicon.ico',
      'download',
      'download/apk',
      'logo.png',
      'screenshots/screen_home.jpg',
      'screenshots/screen_stats.jpg',
      'screenshots/screen_profile.jpg',
      'screenshots/screen_realms.jpg',
      'screenshots/(.*)',
    ],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  logger.log(`Backend server is running on: http://0.0.0.0:${port}/api`);
}
await bootstrap();
