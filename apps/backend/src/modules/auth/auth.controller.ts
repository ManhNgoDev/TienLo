import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';
import { AuthService } from './auth.service.js';
import { SyncUserDto } from './dto/sync-user.dto.js';

@Controller('auth')
@UseGuards(FirebaseAuthGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('sync')
  async syncUser(
    @CurrentUser() user: IAuthUser,
    @Body() dto: SyncUserDto,
  ) {
    return this.authService.syncUser(user, dto);
  }

  @Get('me')
  async getMe(@CurrentUser() user: IAuthUser) {
    return this.authService.getMe(user);
  }
}
