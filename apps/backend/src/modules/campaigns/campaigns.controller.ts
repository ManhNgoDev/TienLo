import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { CampaignsService } from './campaigns.service.js';
import { CreateAiCampaignDto } from './dto/create-ai-campaign.dto.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';

@Controller('campaigns')
@UseGuards(FirebaseAuthGuard, ThrottlerGuard)
export class CampaignsController {
  constructor(private readonly campaignsService: CampaignsService) {}

  // Rate limit: tối đa 5 lần gọi AI tạo chiến dịch / giờ
  @Throttle({ default: { limit: 5, ttl: 3600000 } })
  @Post('ai-generate')
  async createAiCampaign(
    @CurrentUser() user: IAuthUser,
    @Body() dto: CreateAiCampaignDto,
  ) {
    return this.campaignsService.generateAiCampaign(
      user.uid,
      dto.goalPrompt,
      dto.durationDays || 30,
    );
  }

  @Get()
  async getCampaigns(@CurrentUser() user: IAuthUser) {
    return this.campaignsService.getUserCampaigns(user.uid);
  }

  // Rate limit: tối đa 15 lần hoàn thành quest / phút (chống spam farm ảo)
  @Throttle({ default: { limit: 15, ttl: 60000 } })
  @Post('quests/:questId/complete')
  async completeQuest(
    @CurrentUser() user: IAuthUser,
    @Param('questId') questId: string,
  ) {
    return this.campaignsService.completeQuest(user.uid, questId);
  }
}
