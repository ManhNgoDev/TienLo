import { Injectable, Logger } from '@nestjs/common';
import type { IAuthUser } from '../../common/interfaces/auth-user.interface.js';
import { SupabaseService } from '../database/supabase.service.js';
import { SyncUserDto } from './dto/sync-user.dto.js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async syncUser(authUser: IAuthUser, dto?: SyncUserDto) {
    const email = dto?.email || authUser.email || `${authUser.uid}@tienlo.app`;
    const displayName = dto?.displayName || authUser.displayName || 'Đạo Hữu Tiên Lộ';
    let avatarUrl = dto?.photoUrl || authUser.photoUrl || null;
    if (avatarUrl && avatarUrl.includes('images.unsplash.com')) {
      avatarUrl = null;
    }

    this.logger.log(`Đang đồng bộ người dùng: UID=${authUser.uid}, Email=${email}`);

    const user = await this.supabaseService.upsertUser({
      firebase_uid: authUser.uid,
      email,
      display_name: displayName,
      avatar_url: avatarUrl,
    });

    return {
      message: 'Đồng bộ tài khoản thành công',
      user,
    };
  }

  async getMe(authUser: IAuthUser) {
    const user = await this.supabaseService.getUserByFirebaseUid(authUser.uid);
    if (!user) {
      // Tự động tạo nếu chưa có
      return this.syncUser(authUser);
    }
    return {
      user,
    };
  }
}
