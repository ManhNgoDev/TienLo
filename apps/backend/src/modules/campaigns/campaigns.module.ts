import { Module } from '@nestjs/common';
import { CampaignsService } from './campaigns.service.js';
import { CampaignsController } from './campaigns.controller.js';
import { DatabaseModule } from '../database/database.module.js';
import { CultivationModule } from '../cultivation/cultivation.module.js';

@Module({
  imports: [DatabaseModule, CultivationModule],
  controllers: [CampaignsController],
  providers: [CampaignsService],
  exports: [CampaignsService],
})
export class CampaignsModule {}
