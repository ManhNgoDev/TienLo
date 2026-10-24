import { Module } from '@nestjs/common';
import { UsersController } from './users.controller.js';
import { UsersService } from './users.service.js';
import { CultivationModule } from '../cultivation/cultivation.module.js';
import { CampaignsModule } from '../campaigns/campaigns.module.js';

@Module({
  imports: [CultivationModule, CampaignsModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
