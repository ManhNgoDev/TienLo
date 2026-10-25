import { Module } from '@nestjs/common';
import { LandingController } from './landing.controller.js';
import { AppService } from '../../app.service.js';

@Module({
  controllers: [LandingController],
  providers: [AppService],
})
export class LandingModule {}
