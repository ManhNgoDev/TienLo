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
import { GenerateExtraQuestDto } from './dto/generate-extra-quest.dto.js';
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

  // Rate limit: tối đa 15 lần AI tạo nhiệm vụ bổ sung / giờ
  @Throttle({ default: { limit: 15, ttl: 3600000 } })
  @Post('quests/generate-extra')
  async generateExtraQuest(
    @CurrentUser() user: IAuthUser,
    @Body() dto: GenerateExtraQuestDto,
  ) {
    return this.campaignsService.generateExtraQuest(
      user.uid,
      dto.goalPrompt,
      dto.existingTitles || [],
      dto.campaignId,
    );
  }

  @Get()
  async getCampaigns(@CurrentUser() user: IAuthUser) {
    return this.campaignsService.getUserCampaigns(user.uid);
  }

  @Get('statistics')
  async getStatistics(@CurrentUser() user: IAuthUser) {
    return this.campaignsService.getStatistics(user.uid);
  }

  // Rate limit: tối đa 30 lần hoàn thành quest / phút
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @Post('quests/:questId/complete')
  async completeQuest(
    @CurrentUser() user: IAuthUser,
    @Param('questId') questId: string,
    @Body()
    body?: {
      allCompleted?: boolean;
      streakDays?: number;
      localDate?: string;
      questTitle?: string;
      exp?: number;
      spiritStones?: number;
    },
  ) {
    return this.campaignsService.completeQuest(user.uid, questId, body);
  }
}
