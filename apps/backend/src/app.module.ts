import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { DatabaseModule } from './modules/database/database.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { UsersModule } from './modules/users/users.module.js';
import { CultivationModule } from './modules/cultivation/cultivation.module.js';
import { CampaignsModule } from './modules/campaigns/campaigns.module.js';
import { LandingModule } from './modules/landing/landing.module.js';
import { LeaderboardModule } from './modules/leaderboard/leaderboard.module.js';
import { ShopModule } from './modules/shop/shop.module.js';
import { FeedbackModule } from './modules/feedback/feedback.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 60,
      },
    ]),
    DatabaseModule,
    AuthModule,
    UsersModule,
    CultivationModule,
    CampaignsModule,
    LandingModule,
    LeaderboardModule,
    ShopModule,
    FeedbackModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

