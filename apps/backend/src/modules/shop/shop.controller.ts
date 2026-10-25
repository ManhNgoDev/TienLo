import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ShopService } from './shop.service.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';

@Controller('shop')
@UseGuards(FirebaseAuthGuard, ThrottlerGuard)
export class ShopController {
  constructor(private readonly shopService: ShopService) {}

  @Get('items')
  getItems() {
    return this.shopService.getItems();
  }

  @Get('inventory')
  async getInventory(@CurrentUser() user: IAuthUser) {
    return this.shopService.getInventory(user.uid);
  }

  // Giới hạn 20 lần mua / phút chống spam
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @Post('purchase')
  async purchase(
    @CurrentUser() user: IAuthUser,
    @Body('itemId') itemId: string,
    @Body('quantity') quantity?: number,
  ) {
    return this.shopService.purchaseItem(user.uid, itemId, quantity || 1);
  }
}
