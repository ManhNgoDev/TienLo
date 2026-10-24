import { Module } from '@nestjs/common';
import { CultivationService } from './cultivation.service.js';
import { CultivationController } from './cultivation.controller.js';
import { DatabaseModule } from '../database/database.module.js';

@Module({
  imports: [DatabaseModule],
  controllers: [CultivationController],
  providers: [CultivationService],
  exports: [CultivationService],
})
export class CultivationModule {}
