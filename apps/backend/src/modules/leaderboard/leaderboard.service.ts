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

// Danh sách các bậc tiền bối / đạo hữu tiên giới làm mốc leo tháp cạnh tranh
const CULTIVATOR_BENCHMARKS = [
  {
    userId: 'npc-han-lap',
    displayName: 'Hàn Lập (Hàn Thỏ Đế)',
    avatarUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=120',
    streakDays: 15,
    completedQuestsCount: 42,
    realmIndex: 2,
    realmName: 'Kết Đan',
    subRealm: 2,
    realmText: 'Kết Đan Tầng 2',
    totalExp: 18500,
    isNpc: true,
  },
  {
    userId: 'npc-tieu-viem',
    displayName: 'Tiêu Viêm (Viêm Đế)',
    avatarUrl: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=120',
    streakDays: 12,
    completedQuestsCount: 36,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 9,
    realmText: 'Luyện Khí Tầng 9',
    totalExp: 12400,
    isNpc: true,
  },
  {
    userId: 'npc-bach-tieu-thuan',
    displayName: 'Bạch Tiểu Thuần',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
    streakDays: 10,
    completedQuestsCount: 29,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 7,
    realmText: 'Luyện Khí Tầng 7',
    totalExp: 8900,
    isNpc: true,
  },
  {
    userId: 'npc-lam-dong',
    displayName: 'Lâm Động (Vũ Tổ)',
    avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
    streakDays: 7,
    completedQuestsCount: 21,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 5,
    realmText: 'Luyện Khí Tầng 5',
    totalExp: 5400,
    isNpc: true,
  },
  {
    userId: 'npc-diep-pham',
    displayName: 'Diệp Phàm (Diệp Thiên Đế)',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
    streakDays: 5,
    completedQuestsCount: 16,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 4,
    realmText: 'Luyện Khí Tầng 4',
    totalExp: 3800,
    isNpc: true,
  },
  {
    userId: 'npc-thach-hao',
    displayName: 'Thạch Hạo (Hoang Thiên Đế)',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=120',
    streakDays: 4,
    completedQuestsCount: 12,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 3,
    realmText: 'Luyện Khí Tầng 3',
    totalExp: 2600,
    isNpc: true,
  },
  {
    userId: 'npc-muc-tran',
    displayName: 'Mục Trần (Mục Chủ)',
    avatarUrl: 'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=120',
    streakDays: 2,
    completedQuestsCount: 7,
    realmIndex: 1,
    realmName: 'Luyện Khí',
    subRealm: 2,
    realmText: 'Luyện Khí Tầng 2',
    totalExp: 1500,
    isNpc: true,
  },
  {
    userId: 'npc-vuong-lam',
    displayName: 'Vương Lâm (Nghịch Tu)',
    avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=120',
    streakDays: 1,
    completedQuestsCount: 4,
    realmIndex: 0,
    realmName: 'Phàm Nhân',
    subRealm: 1,
    realmText: 'Phàm Nhân Tầng 1',
    totalExp: 450,
    isNpc: true,
  },
];

@Injectable()
export class LeaderboardService {
  private readonly logger = new Logger(LeaderboardService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Lấy danh sách Bảng Xếp Hạng Tiên Lộ
   * Logic xếp hạng theo đúng yêu cầu:
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

    // 1. Thêm toàn bộ người dùng thực từ DB
    for (const u of dbUsers) {
      const uid = u.firebase_uid;
      if (!uid || seenUids.has(uid)) continue;
      seenUids.add(uid);

      const cult = cultMap.get(uid);
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

      const completedCount = completedQuestsMap.get(uid) || 0;

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

    // 2. Thêm các tiền bối NPC nếu danh sách dưới 15 người để bảng luôn sinh động
    for (const npc of CULTIVATOR_BENCHMARKS) {
      if (!seenUids.has(npc.userId)) {
        mergedList.push(npc);
      }
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
