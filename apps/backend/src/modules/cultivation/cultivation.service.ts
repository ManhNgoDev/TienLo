import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../database/supabase.service.js';
import {
  CULTIVATION_REALMS,
  calculateSubRealmExp,
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
  lastActiveDate?: string;
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
    return config || CULTIVATION_REALMS[0]; // Mặc định Phàm Nhân
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
          const maxExp = calculateSubRealmExp(data.realm_index, data.sub_realm);
          let streakDays = data.streak_days != null ? Number(data.streak_days) : 0;
          // Chuẩn hóa tài khoản mới chưa hoàn thành quest nào về streak 0
          if (Number(data.total_exp || 0) === 0 && Number(data.current_exp || 0) === 0 && streakDays === 1) {
            streakDays = 0;
          }
          return {
            userId: data.user_id,
            realmIndex: data.realm_index,
            realmName: data.realm_name || realmConfig.name,
            subRealm: data.sub_realm,
            currentExp: data.current_exp,
            maxExp,
            totalExp: Number(data.total_exp || 0),
            spiritStones: data.spirit_stones,
            streakDays,
            lastActiveDate: data.last_active_date || undefined,
            title: realmConfig.title,
            allRealms: CULTIVATION_REALMS,
          };
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi Supabase getProfile: ${err.message}`);
      }
    }

    // In-memory fallback (Khởi đầu: Phàm Nhân, 0 / 1.000 EXP, 0 Nguyên Thạch, 0 Chuỗi ngày)
    if (!this.inMemoryState.has(userId)) {
      const defaultRealm = CULTIVATION_REALMS[0]; // Phàm Nhân
      this.inMemoryState.set(userId, {
        userId,
        realmIndex: 0,
        realmName: defaultRealm.name,
        subRealm: 1,
        currentExp: 0,
        maxExp: calculateSubRealmExp(0, 1),
        totalExp: 0,
        spiritStones: 0,
        streakDays: 0,
        title: defaultRealm.title,
        allRealms: CULTIVATION_REALMS,
      });
    }

    return this.inMemoryState.get(userId)!;
  }

  async incrementStreakIfEligible(
    userId: string,
    dateStr?: string,
    _targetStreak?: number,
  ): Promise<{ profile: UserCultivationState; streakIncremented: boolean }> {
    const profile = await this.getProfile(userId);
    const todayStr = dateStr || new Date().toISOString().split('T')[0];

    const client = this.supabaseService.getClient();
    let shouldIncrement = true;

    if (profile.lastActiveDate === todayStr && (profile.streakDays || 0) > 0) {
      shouldIncrement = false;
    }

    if (client) {
      try {
        const { data } = await client
          .from('user_cultivations')
          .select('last_active_date, streak_days')
          .eq('user_id', userId)
          .maybeSingle();

        if (data && data.last_active_date === todayStr && Number(data.streak_days || 0) > 0) {
          shouldIncrement = false;
        }
      } catch (_) {}
    }

    // Tuyệt đối mỗi ngày chỉ được tăng tối đa +1 chuỗi ngày, kể cả khi tạo và làm thêm nhiệm vụ
    if (!shouldIncrement) {
      return { profile, streakIncremented: false };
    }

    const newStreakDays = (profile.streakDays || 0) + 1;

    const updatedProfile: UserCultivationState = {
      ...profile,
      streakDays: newStreakDays,
      lastActiveDate: todayStr,
    };

    if (client) {
      try {
        await client
          .from('user_cultivations')
          .upsert({
            user_id: userId,
            realm_index: profile.realmIndex,
            realm_name: profile.realmName,
            sub_realm: profile.subRealm,
            current_exp: profile.currentExp,
            max_exp: profile.maxExp,
            total_exp: profile.totalExp,
            spirit_stones: profile.spiritStones,
            streak_days: newStreakDays,
            last_active_date: todayStr,
            updated_at: new Date().toISOString(),
          }, { onConflict: 'user_id' });
      } catch (err: any) {
        this.logger.warn(`Lỗi cập nhật streak_days: ${err?.message}`);
      }
    }

    this.inMemoryState.set(userId, updatedProfile);
    return { profile: updatedProfile, streakIncremented: true };
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

    // Tính toán thăng tầng hoặc thăng cảnh giới
    while (currentExp >= maxExp && realmIndex < 9) {
      if (subRealm < realmConfig.subRealms) {
        // Thăng tầng trong cảnh giới (Tầng 1 -> Tầng 2 -> ... -> Tầng 10)
        subRealm += 1;
        currentExp -= maxExp;
        maxExp = calculateSubRealmExp(realmIndex, subRealm);
        levelUp = true;
      } else {
        // Đột phá sang cảnh giới kế tiếp!
        realmIndex += 1;
        subRealm = 1;
        currentExp -= maxExp;
        realmConfig = this.getRealmConfig(realmIndex);
        maxExp = calculateSubRealmExp(realmIndex, subRealm);
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
          streak_days: profile.streakDays,
          spirit_stones: profile.spiritStones,
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

  async penalizeExp(
    userId: string,
    uncompletedCount: number,
    customPenalty?: number,
    reason?: string,
  ): Promise<{
    profile: UserCultivationState;
    penaltyExp: number;
    uncompletedCount: number;
    reason: string;
    demotedLevel: boolean;
    demotedRealm: boolean;
    previousRealmName: string;
    previousSubRealm: number;
    currentRealmName: string;
    currentSubRealm: number;
  }> {
    const profile = await this.getProfile(userId);
    let { realmIndex, subRealm, currentExp, maxExp, totalExp, streakDays, spiritStones } = profile;

    const prevRealmIndex = realmIndex;
    const prevSubRealm = subRealm;
    const prevRealmName = profile.realmName;

    // Tính toán lượng linh lực phạt: nếu có customPenalty thì áp dụng, mặc định giới hạn tối đa 300
    const penaltyExp = customPenalty && customPenalty > 0
      ? customPenalty
      : Math.min(300, Math.max(50, (uncompletedCount || 1) * 80));

    const actualReason = reason || `Chưa hoàn thành ${uncompletedCount || 1} nhiệm vụ hôm qua, bị trừ ${penaltyExp} Linh Lực!`;

    // BẢO TOÀN NGUYÊN VẸN CHUỖI NGÀY VÀ LINH THẠCH CỦA ĐẠO HỮU (TUYỆT ĐỐI KHÔNG RESET):
    // streakDays và spiritStones giữ nguyên

    // Trừ linh lực
    currentExp -= penaltyExp;
    totalExp = Math.max(0, totalExp - penaltyExp);

    let demotedLevel = false;
    let demotedRealm = false;

    let realmConfig = this.getRealmConfig(realmIndex);

    // Xử lý tụt tầng và tụt cảnh giới
    while (currentExp < 0) {
      // RULE BẢO HIỂM: Nếu ở Luyện Khí Tầng 1, không bao giờ tụt xuống Phàm Nhân, dừng lại ở Luyện Khí Tầng 1 (0 Linh Lực)
      if (realmIndex === 1 && subRealm === 1) {
        currentExp = 0;
        break;
      }

      // Nếu đang là Phàm Nhân (realm 0), sàn là 0 Linh Lực
      if (realmIndex === 0) {
        currentExp = 0;
        break;
      }

      if (subRealm > 1) {
        // Tụt tầng trong cảnh giới (Tầng X -> Tầng X - 1)
        subRealm -= 1;
        maxExp = calculateSubRealmExp(realmIndex, subRealm);
        currentExp = maxExp + currentExp; // currentExp âm nên sẽ thành maxExp - |currentExp|
        demotedLevel = true;
      } else {
        // subRealm === 1 và realmIndex > 1: Tụt Cảnh Giới!
        realmIndex -= 1;
        subRealm = 10;
        realmConfig = this.getRealmConfig(realmIndex);
        maxExp = calculateSubRealmExp(realmIndex, 10);
        currentExp = maxExp + currentExp;
        demotedLevel = true;
        demotedRealm = true;
      }
    }

    realmConfig = this.getRealmConfig(realmIndex);

    const updatedProfile: UserCultivationState = {
      ...profile,
      realmIndex,
      realmName: realmConfig.name,
      subRealm,
      currentExp,
      maxExp,
      totalExp,
      streakDays,
      spiritStones,
      title: realmConfig.title,
    };

    // Lưu vào database
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
          streak_days: streakDays,
          spirit_stones: spiritStones,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });
      } catch (_) {}
    }

    this.inMemoryState.set(userId, updatedProfile);

    return {
      profile: updatedProfile,
      penaltyExp,
      uncompletedCount,
      reason: actualReason,
      demotedLevel,
      demotedRealm,
      previousRealmName: prevRealmName,
      previousSubRealm: prevSubRealm,
      currentRealmName: realmConfig.name,
      currentSubRealm: subRealm,
    };
  }
}
