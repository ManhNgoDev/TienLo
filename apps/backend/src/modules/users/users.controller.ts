import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';
import { UsersService } from './users.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Controller('users')
@UseGuards(FirebaseAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: IAuthUser) {
    return this.usersService.getProfile(
      user.uid,
      user.email,
      user.displayName,
      user.photoUrl,
    );
  }

  @Put('profile')
  async updateProfile(
    @CurrentUser() user: IAuthUser,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(user.uid, dto);
  }

  @Get('achievements')
  async getAchievements(@CurrentUser() user: IAuthUser) {
    const profile = await this.usersService.getProfile(
      user.uid,
      user.email,
      user.displayName,
      user.photoUrl,
    );
    return profile.allAchievements;
  }
}
