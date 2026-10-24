import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../database/supabase.service.js';
import {
  CULTIVATION_REALMS,
  type CultivationRealmConfig,
} from './cultivation.constants.js';

export interface UserCultivationState {
  userId: string;
  realmIndex: number;
  realmName: string;
  subRealm: number; // 1 - 10
  currentExp: number;
  maxExp: number;
  totalExp: number;
  spiritStones: number;
  streakDays: number;
  title: string;
  allRealms: CultivationRealmConfig[];
}

@Injectable()
export class CultivationService {
  private readonly logger = new Logger(CultivationService.name);

  // In-memory fallback
  private readonly inMemoryState = new Map<string, UserCultivationState>();

  constructor(private readonly supabaseService: SupabaseService) {}

  private getRealmConfig(realmIndex: number): CultivationRealmConfig {
    const config = CULTIVATION_REALMS.find((r: CultivationRealmConfig) => r.index === realmIndex);
    return config || CULTIVATION_REALMS[1]; // Mặc định Luyện Khí
  }

  async getProfile(userId: string): Promise<UserCultivationState> {
    const client = this.supabaseService.getClient();

    if (client) {
      try {
        const { data, error } = await client
          .from('user_cultivations')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

        if (error) {
          this.logger.warn(`Lỗi đọc user_cultivations: ${error.message}`);
        } else if (data) {
          const realmConfig = this.getRealmConfig(data.realm_index);
          return {
            userId: data.user_id,
            realmIndex: data.realm_index,
            realmName: data.realm_name || realmConfig.name,
            subRealm: data.sub_realm,
            currentExp: data.current_exp,
            maxExp: data.max_exp || realmConfig.expPerSubRealm,
            totalExp: Number(data.total_exp || 0),
            spiritStones: data.spirit_stones,
            streakDays: data.streak_days,
            title: realmConfig.title,
            allRealms: CULTIVATION_REALMS,
          };
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi Supabase getProfile: ${err.message}`);
      }
    }

    // In-memory fallback (Khởi đầu: Luyện Khí Bậc 1, 0 / 1.000 EXP, 50 Linh Thạch)
    if (!this.inMemoryState.has(userId)) {
      const defaultRealm = CULTIVATION_REALMS[1]; // Luyện Khí
      this.inMemoryState.set(userId, {
        userId,
        realmIndex: 1,
        realmName: defaultRealm.name,
        subRealm: 1,
        currentExp: 0,
        maxExp: defaultRealm.expPerSubRealm,
        totalExp: 0,
        spiritStones: 50,
        streakDays: 1,
        title: defaultRealm.title,
        allRealms: CULTIVATION_REALMS,
      });
    }

    return this.inMemoryState.get(userId)!;
  }

  async addExp(
    userId: string,
    amount: number,
  ): Promise<{ profile: UserCultivationState; levelUp: boolean; realmUp: boolean }> {
    const profile = await this.getProfile(userId);
    let { realmIndex, subRealm, currentExp, maxExp, totalExp } = profile;

    totalExp += amount;
    currentExp += amount;
    let levelUp = false;
    let realmUp = false;

    let realmConfig = this.getRealmConfig(realmIndex);

    // Tính toán thăng bậc hoặc thăng cảnh giới
    while (currentExp >= maxExp && realmIndex < 9) {
      if (subRealm < 10) {
        // Thăng bậc trong cảnh giới (1 -> 10)
        subRealm += 1;
        currentExp -= maxExp;
        levelUp = true;
      } else {
        // Đột phá sang cảnh giới kế tiếp!
        realmIndex += 1;
        subRealm = 1;
        currentExp -= maxExp;
        realmConfig = this.getRealmConfig(realmIndex);
        maxExp = realmConfig.expPerSubRealm;
        levelUp = true;
        realmUp = true;
      }
    }

    // Cực cảnh Phi Tiên
    if (realmIndex >= 9) {
      realmIndex = 9;
      subRealm = 1;
      maxExp = 9999999;
    }

    const updatedProfile: UserCultivationState = {
      ...profile,
      realmIndex,
      realmName: realmConfig.name,
      subRealm,
      currentExp,
      maxExp,
      totalExp,
      title: realmConfig.title,
    };

    // Lưu vào Supabase hoặc in-memory
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        await client.from('user_cultivations').upsert({
          user_id: userId,
          realm_index: realmIndex,
          realm_name: realmConfig.name,
          sub_realm: subRealm,
          current_exp: currentExp,
          max_exp: maxExp,
          total_exp: totalExp,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });
      } catch (_) {}
    }

    this.inMemoryState.set(userId, updatedProfile);

    return { profile: updatedProfile, levelUp, realmUp };
  }

  async addSpiritStones(
    userId: string,
    amount: number,
    description: string,
  ): Promise<UserCultivationState> {
    const profile = await this.getProfile(userId);
    const newStones = Math.max(0, profile.spiritStones + amount);

    const updatedProfile: UserCultivationState = {
      ...profile,
      spiritStones: newStones,
    };

    const client = this.supabaseService.getClient();
    if (client) {
      try {
        await client
          .from('user_cultivations')
          .update({
            spirit_stones: newStones,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', userId);

        await client.from('spirit_stone_transactions').insert({
          user_id: userId,
          amount,
          type: amount >= 0 ? 'REWARD' : 'SPEND',
          description,
        });
      } catch (_) {}
    }

    this.inMemoryState.set(userId, updatedProfile);
    return updatedProfile;
  }
}
