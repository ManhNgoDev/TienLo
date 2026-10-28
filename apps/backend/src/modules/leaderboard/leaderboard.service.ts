import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../database/supabase.service.js';
import { CULTIVATION_REALMS } from '../cultivation/cultivation.constants.js';

export interface LeaderboardEntry {
  rank: number;
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  streakDays: number;
  completedQuestsCount: number;
  realmIndex: number;
  realmName: string;
  subRealm: number;
  realmText: string;
  totalExp: number;
  isCurrentUser: boolean;
  isNpc?: boolean;
}

export interface LeaderboardResponse {
  success: boolean;
  sortBy: string;
  totalUsers: number;
  currentUser?: LeaderboardEntry | null;
  leaderboard: LeaderboardEntry[];
}

@Injectable()
export class LeaderboardService {
  private readonly logger = new Logger(LeaderboardService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Lấy danh sách Bảng Xếp Hạng Tiên Lộ từ người chơi thật trong database
   * Logic xếp hạng:
   * 1. Chuỗi ngày tu luyện (streakDays) giảm dần
   * 2. Số nhiệm vụ hoàn thành (completedQuestsCount) giảm dần
   * 3. Cảnh giới tầng X (realmIndex * 100 + subRealm) giảm dần
   * 4. Tổng kinh nghiệm (totalExp) giảm dần
   */
  async getLeaderboard(
    currentUserId?: string,
    sortBy: string = 'default',
    limit: number = 50,
  ): Promise<LeaderboardResponse> {
    const client = this.supabaseService.getClient();

    let dbUsers: any[] = [];
    let dbCultivations: any[] = [];
    let dbQuests: any[] = [];

    if (client) {
      try {
        const [usersRes, cultRes, questsRes] = await Promise.all([
          client.from('users').select('*'),
          client.from('user_cultivations').select('*'),
          client.from('quests').select('user_id, is_completed, is_xp_claimed'),
        ]);

        if (usersRes.data) dbUsers = usersRes.data;
        if (cultRes.data) dbCultivations = cultRes.data;
        if (questsRes.data) dbQuests = questsRes.data;
      } catch (err: any) {
        this.logger.warn(`Lỗi truy vấn dữ liệu leaderboard: ${err.message}`);
      }
    }

    // Dự phòng khi client rỗng hoặc chạy in-memory
    if (dbUsers.length === 0) {
      dbUsers = this.supabaseService.getInMemoryUsers();
    }

    // Đếm số nhiệm vụ hoàn thành theo user_id
    const completedQuestsMap = new Map<string, number>();
    for (const q of dbQuests) {
      if (q.is_completed || q.is_xp_claimed) {
        const count = completedQuestsMap.get(q.user_id) || 0;
        completedQuestsMap.set(q.user_id, count + 1);
      }
    }

    // Bản đồ thông tin tu tiên theo user_id
    const cultMap = new Map<string, any>();
    for (const c of dbCultivations) {
      cultMap.set(c.user_id, c);
    }

    const mergedList: Omit<LeaderboardEntry, 'rank' | 'isCurrentUser'>[] = [];
    const seenUids = new Set<string>();

    // 1. Thêm toàn bộ người dùng thực từ Database
    for (const u of dbUsers) {
      const uid = u.firebase_uid || u.id;
      if (!uid || seenUids.has(uid)) continue;
      seenUids.add(uid);

      const cult = cultMap.get(uid) || cultMap.get(u.id);
      const streakDays = cult?.streak_days != null ? Number(cult.streak_days) : 0;
      const realmIndex = cult?.realm_index != null ? Number(cult.realm_index) : 0;
      const subRealm = cult?.sub_realm != null ? Number(cult.sub_realm) : 1;
      const totalExp = cult?.total_exp != null ? Number(cult.total_exp) : 0;
      const realmName = cult?.realm_name || (CULTIVATION_REALMS[realmIndex]?.name ?? 'Phàm Nhân');

      let realmText = `${realmName} Tầng ${subRealm}`;
      if (realmIndex === 0) {
        realmText = 'Phàm Nhân';
      }

      let cleanAvatarUrl = u.avatar_url || null;
      if (cleanAvatarUrl && cleanAvatarUrl.includes('images.unsplash.com')) {
        cleanAvatarUrl = null;
      }

      let displayName = u.display_name?.trim();
      if (!displayName || displayName === 'TienLo Demo User') {
        displayName = u.email ? u.email.split('@')[0] : 'Đạo Hữu Tiên Lộ';
      }

      const completedCount =
        completedQuestsMap.get(uid) ||
        (u.id ? completedQuestsMap.get(u.id) || 0 : 0);

      mergedList.push({
        userId: uid,
        displayName,
        avatarUrl: cleanAvatarUrl,
        streakDays,
        completedQuestsCount: completedCount,
        realmIndex,
        realmName,
        subRealm,
        realmText,
        totalExp,
        isNpc: false,
      });
    }

    // 2. Đảm bảo người dùng hiện tại (currentUserId) luôn có mặt trong bảng xếp hạng nếu chưa có trong DB
    if (currentUserId && !seenUids.has(currentUserId)) {
      seenUids.add(currentUserId);
      const cult = cultMap.get(currentUserId);
      const streakDays = cult?.streak_days != null ? Number(cult.streak_days) : 0;
      const realmIndex = cult?.realm_index != null ? Number(cult.realm_index) : 0;
      const subRealm = cult?.sub_realm != null ? Number(cult.sub_realm) : 1;
      const totalExp = cult?.total_exp != null ? Number(cult.total_exp) : 0;
      const realmName = cult?.realm_name || (CULTIVATION_REALMS[realmIndex]?.name ?? 'Phàm Nhân');

      mergedList.push({
        userId: currentUserId,
        displayName: 'Đạo Hữu Tiên Lộ (Bạn)',
        avatarUrl: null,
        streakDays,
        completedQuestsCount: completedQuestsMap.get(currentUserId) || 0,
        realmIndex,
        realmName,
        subRealm,
        realmText: realmIndex === 0 ? 'Phàm Nhân' : `${realmName} Tầng ${subRealm}`,
        totalExp,
        isNpc: false,
      });
    }

    // 3. Sắp xếp thứ hạng theo logic
    mergedList.sort((a, b) => {
      if (sortBy === 'streak') {
        if (b.streakDays !== a.streakDays) return b.streakDays - a.streakDays;
        if (b.completedQuestsCount !== a.completedQuestsCount) return b.completedQuestsCount - a.completedQuestsCount;
        const realmScoreA = a.realmIndex * 100 + a.subRealm;
        const realmScoreB = b.realmIndex * 100 + b.subRealm;
        return realmScoreB - realmScoreA;
      }

      if (sortBy === 'quests') {
        if (b.completedQuestsCount !== a.completedQuestsCount) return b.completedQuestsCount - a.completedQuestsCount;
        if (b.streakDays !== a.streakDays) return b.streakDays - a.streakDays;
        const realmScoreA = a.realmIndex * 100 + a.subRealm;
        const realmScoreB = b.realmIndex * 100 + b.subRealm;
        return realmScoreB - realmScoreA;
      }

      if (sortBy === 'realm') {
        const realmScoreA = a.realmIndex * 100 + a.subRealm;
        const realmScoreB = b.realmIndex * 100 + b.subRealm;
        if (realmScoreB !== realmScoreA) return realmScoreB - realmScoreA;
        if (b.streakDays !== a.streakDays) return b.streakDays - a.streakDays;
        return b.completedQuestsCount - a.completedQuestsCount;
      }

      // Mặc định: Chuỗi ngày -> Số nhiệm vụ hoàn thành -> Cảnh giới tầng X -> Kinh nghiệm
      if (b.streakDays !== a.streakDays) {
        return b.streakDays - a.streakDays;
      }
      if (b.completedQuestsCount !== a.completedQuestsCount) {
        return b.completedQuestsCount - a.completedQuestsCount;
      }
      const realmScoreA = a.realmIndex * 100 + a.subRealm;
      const realmScoreB = b.realmIndex * 100 + b.subRealm;
      if (realmScoreB !== realmScoreA) {
        return realmScoreB - realmScoreA;
      }
      return b.totalExp - a.totalExp;
    });

    // 4. Đánh số hạng (Rank 1, 2, 3...)
    const rankedList: LeaderboardEntry[] = mergedList.map((entry, index) => {
      const isCurrent = Boolean(currentUserId && entry.userId === currentUserId);
      return {
        ...entry,
        rank: index + 1,
        isCurrentUser: isCurrent,
      };
    });

    // 5. Xác định vị trí của currentUser
    let currentUserEntry: LeaderboardEntry | null = null;
    if (currentUserId) {
      currentUserEntry = rankedList.find((e) => e.userId === currentUserId) || null;
    }

    return {
      success: true,
      sortBy,
      totalUsers: rankedList.length,
      currentUser: currentUserEntry,
      leaderboard: rankedList.slice(0, limit),
    };
  }
}
