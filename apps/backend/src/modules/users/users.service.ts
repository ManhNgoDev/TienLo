import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../database/supabase.service.js';

@Injectable()
export class UsersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getProfile(firebaseUid: string) {
    const user = await this.supabaseService.getUserByFirebaseUid(firebaseUid);
    if (!user) {
      throw new NotFoundException('Không tìm thấy thông tin người dùng');
    }
    return user;
  }
}
