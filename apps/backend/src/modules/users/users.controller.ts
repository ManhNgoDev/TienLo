import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator.js';
import { FirebaseAuthGuard } from '../../common/guards/firebase-auth.guard.js';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';
import { UsersService } from './users.service.js';

@Controller('users')
@UseGuards(FirebaseAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: IAuthUser) {
    return this.usersService.getProfile(user.uid);
  }
}
