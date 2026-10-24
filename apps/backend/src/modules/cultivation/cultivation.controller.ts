import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CultivationService } from './cultivation.service.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';

@Controller('cultivation')
@UseGuards(FirebaseAuthGuard)
export class CultivationController {
  constructor(private readonly cultivationService: CultivationService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: IAuthUser) {
    return this.cultivationService.getProfile(user.uid);
  }

  @Post('add-exp')
  async addExp(
    @CurrentUser() user: IAuthUser,
    @Body('amount') amount: number,
  ) {
    const validAmount = Math.max(0, Number(amount) || 0);
    return this.cultivationService.addExp(user.uid, validAmount);
  }

  @Post('add-stones')
  async addStones(
    @CurrentUser() user: IAuthUser,
    @Body('amount') amount: number,
    @Body('description') description: string,
  ) {
    const validAmount = Number(amount) || 0;
    return this.cultivationService.addSpiritStones(
      user.uid,
      validAmount,
      description || 'Thưởng hoạt động tu tiên',
    );
  }
}
