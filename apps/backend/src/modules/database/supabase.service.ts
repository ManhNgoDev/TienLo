import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

export interface UserRecord {
  id: string;
  firebase_uid: string;
  email: string;
  display_name?: string;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
}

@Injectable()
export class SupabaseService implements OnModuleInit {
  private readonly logger = new Logger(SupabaseService.name);
  private client: SupabaseClient | null = null;

  // In-memory fallback khi dev chưa tạo bảng hoặc chưa điền credentials Supabase
  private readonly inMemoryUsers = new Map<string, UserRecord>();

  onModuleInit() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey =
      process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

    if (supabaseUrl && supabaseKey) {
      try {
        this.client = createClient(supabaseUrl, supabaseKey, {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        });
        this.logger.log('Đã kết nối thành công tới Supabase Database!');
      } catch (err) {
        this.logger.error('Lỗi khởi tạo Supabase Client:', err);
      }
    } else {
      this.logger.warn(
        'SUPABASE_URL hoặc SUPABASE_KEY chưa được thiết lập trong .env. Sử dụng bộ nhớ tạm (In-memory store) cho môi trường phát triển.',
      );
    }
  }

  getClient(): SupabaseClient | null {
    return this.client;
  }

  async upsertUser(data: {
    firebase_uid: string;
    email: string;
    display_name?: string;
    avatar_url?: string;
  }): Promise<UserRecord> {
    const now = new Date().toISOString();

    if (this.client) {
      try {
        const { data: user, error } = await this.client
          .from('users')
          .upsert(
            {
              firebase_uid: data.firebase_uid,
              email: data.email,
              display_name: data.display_name,
              avatar_url: data.avatar_url,
              updated_at: now,
            },
            { onConflict: 'firebase_uid' },
          )
          .select()
          .maybeSingle();

        if (error) {
          this.logger.warn(
            `Chưa tìm thấy bảng 'users' trên Supabase (${error.message}). Tạm thời lưu user vào bộ nhớ đệm để không gián đoạn đăng nhập. Hãy tạo bảng 'users' trên Supabase SQL Editor.`,
          );
        } else if (user) {
          return user as UserRecord;
        }
      } catch (err: any) {
        this.logger.warn(
          `Lỗi kết nối bảng Supabase: ${err.message || err}. Dùng bộ nhớ tạm.`,
        );
      }
    }

    // In-memory fallback
    const existing = this.inMemoryUsers.get(data.firebase_uid);
    const record: UserRecord = {
      id: existing ? existing.id : `user-${data.firebase_uid.substring(0, 8)}`,
      firebase_uid: data.firebase_uid,
      email: data.email,
      display_name:
        data.display_name || existing?.display_name || 'Người dùng TienLo',
      avatar_url: data.avatar_url || existing?.avatar_url,
      created_at: existing ? existing.created_at : now,
      updated_at: now,
    };
    this.inMemoryUsers.set(data.firebase_uid, record);
    return record;
  }

  async getUserByFirebaseUid(firebase_uid: string): Promise<UserRecord | null> {
    if (this.client) {
      try {
        const { data: user, error } = await this.client
          .from('users')
          .select('*')
          .eq('firebase_uid', firebase_uid)
          .maybeSingle();

        if (error) {
          this.logger.warn(`Lỗi Supabase getUserByFirebaseUid: ${error.message}`);
        } else if (user) {
          return user as UserRecord;
        }
      } catch (_) {}
    }

    return this.inMemoryUsers.get(firebase_uid) || null;
  }
}
