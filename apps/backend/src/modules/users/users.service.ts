import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../database/supabase.service.js';
import { CultivationService } from '../cultivation/cultivation.service.js';
import { CampaignsService } from '../campaigns/campaigns.service.js';
import { UpdateProfileDto } from './dto/update-profile.dto.js';

@Injectable()
export class UsersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly cultivationService: CultivationService,
    private readonly campaignsService: CampaignsService,
  ) {}

  async getProfile(firebaseUid: string, email?: string, name?: string, photo?: string) {
    let cleanAvatarUrl = photo || null;
    if (cleanAvatarUrl && cleanAvatarUrl.includes('images.unsplash.com')) {
      cleanAvatarUrl = null;
    }

    let user = await this.supabaseService.getUserByFirebaseUid(firebaseUid);
    if (!user) {
      user = await this.supabaseService.upsertUser({
        firebase_uid: firebaseUid,
        email: email || `${firebaseUid}@tienlo.app`,
        display_name: name || 'Đạo Hữu Tiên Lộ',
        avatar_url: cleanAvatarUrl,
      });
    } else {
      let needsUpdate = false;
      let newEmail = user.email;
      let newAvatar: string | null | undefined = user.avatar_url;

      if (user.avatar_url && user.avatar_url.includes('images.unsplash.com')) {
        newAvatar = cleanAvatarUrl;
        needsUpdate = true;
      }
      if (email && (!user.email || user.email.includes('demo.user') || user.email.includes('placeholder'))) {
        newEmail = email;
        needsUpdate = true;
      }

      if (needsUpdate) {
        user = await this.supabaseService.upsertUser({
          firebase_uid: firebaseUid,
          email: newEmail,
          display_name: user.display_name || name || 'Đạo Hữu Tiên Lộ',
          avatar_url: newAvatar,
        });
      }
    }

    if (user.avatar_url && user.avatar_url.includes('images.unsplash.com')) {
      cleanAvatarUrl = null;
    } else {
      cleanAvatarUrl = user.avatar_url || cleanAvatarUrl;
    }

    const cultivation = await this.cultivationService.getProfile(firebaseUid);
    const campaigns = await this.campaignsService.getUserCampaigns(firebaseUid);

    // Calculate total lifetime completed quests from campaigns + quests table + reward transactions
    let completedQuestsFromCamps = 0;
    for (const c of campaigns) {
      completedQuestsFromCamps += (c.quests || []).filter((q: any) => q.isCompleted || q.isXpClaimed).length;
    }

    let completedFromQuestsTable = 0;
    let completedFromRewardTx = 0;
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        const [qRes, txRes] = await Promise.all([
          client
            .from('quests')
            .select('id, is_completed, is_xp_claimed')
            .eq('user_id', firebaseUid),
          client
            .from('spirit_stone_transactions')
            .select('id, amount, type')
            .eq('user_id', firebaseUid)
            .gt('amount', 0),
        ]);
        if (qRes.data) {
          completedFromQuestsTable = qRes.data.filter(
            (q: any) => q.is_completed || q.is_xp_claimed,
          ).length;
        }
        if (txRes.data) {
          completedFromRewardTx = txRes.data.length;
        }
      } catch (_) {}
    }

    const completedQuests = Math.max(
      completedQuestsFromCamps,
      completedFromQuestsTable,
      completedFromRewardTx,
    );

    // Format joinedDate
    let joinedDate = 'Người chơi từ 06/2024';
    if (user.created_at) {
      try {
        const d = new Date(user.created_at);
        const mm = (d.getMonth() + 1).toString().padStart(2, '0');
        const yyyy = d.getFullYear();
        joinedDate = `Người chơi từ ${mm}/${yyyy}`;
      } catch (_) {}
    }

    let rawUsername = 'daohuu';
    if (user.email && !user.email.includes('demo.user') && !user.email.includes('placeholder')) {
      rawUsername = user.email.split('@')[0];
    } else if (user.display_name && user.display_name !== 'TienLo Demo User' && user.display_name !== 'Đạo Hữu Tiên Lộ') {
      rawUsername = user.display_name
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/đ/g, 'd')
        .replace(/Đ/g, 'D');
    }
    const username = rawUsername.toLowerCase().replace(/[^a-z0-9_]/g, '');

    // Next title & progress
    let nextTitle = 'Phàm Nhân • Đột phá Tiên Lộ';
    if (cultivation.realmIndex === 0) {
      nextTitle = 'Luyện Khí Tầng 1 • Tiên Lộ Tu Sĩ';
    } else if (cultivation.subRealm < 10) {
      nextTitle = `${cultivation.realmName} Tầng ${cultivation.subRealm + 1}`;
    } else {
      const nextRealm = cultivation.allRealms.find((r: any) => r.index === cultivation.realmIndex + 1);
      nextTitle = nextRealm ? `${nextRealm.name} Tầng 1 • Đột Phá Cảnh Giới` : 'Cực Cảnh Phi Tiên';
    }

    const progressPercent = cultivation.maxExp > 0
      ? Math.min(100, Math.round((cultivation.currentExp / cultivation.maxExp) * 100))
      : 100;
    const expNeeded = Math.max(0, cultivation.maxExp - cultivation.currentExp);

    // Rank badge
    let rankBadge = 'Rank Đồng • Top 30%';
    if (cultivation.realmIndex >= 2 || cultivation.streakDays >= 20) {
      rankBadge = 'Rank Vàng • Top 5%';
    } else if (cultivation.realmIndex >= 1 || cultivation.streakDays >= 7) {
      rankBadge = 'Rank Bạc • Top 18%';
    }

    const goldCoins = Math.floor(cultivation.totalExp * 0.5) + cultivation.spiritStones * 10 + 120;

    const featuredAchievements = [
      {
        id: 'ach-streak-7',
        icon: 'flame',
        title: 'Bền bỉ',
        subtitle: '7 ngày liên tiếp',
        progress: cultivation.streakDays,
        maxProgress: 7,
        isUnlocked: cultivation.streakDays >= 7,
      },
      {
        id: 'ach-quests-50',
        icon: 'trophy',
        title: 'Khởi đầu',
        subtitle: '50 nhiệm vụ',
        progress: completedQuests,
        maxProgress: 50,
        isUnlocked: completedQuests >= 50,
      },
      {
        id: 'ach-focus-500',
        icon: 'bolt',
        title: 'Tập trung',
        subtitle: '500 phút',
        progress: Math.min(500, completedQuests * 15),
        maxProgress: 500,
        isUnlocked: completedQuests * 15 >= 500,
      },
    ];

    const allAchievements = [
      ...featuredAchievements,
      {
        id: 'ach-breakthrough-1',
        icon: 'auto_awesome',
        title: 'Đột phá Tiên Lộ',
        subtitle: 'Bước chân vào Luyện Khí',
        progress: cultivation.realmIndex >= 1 ? 1 : 0,
        maxProgress: 1,
        isUnlocked: cultivation.realmIndex >= 1,
      },
      {
        id: 'ach-stones-100',
        icon: 'diamond',
        title: 'Đại Gia Tu Tiên',
        subtitle: 'Tích lũy 100 Nguyên Thạch',
        progress: cultivation.spiritStones,
        maxProgress: 100,
        isUnlocked: cultivation.spiritStones >= 100,
      },
      {
        id: 'ach-streak-30',
        icon: 'medal',
        title: 'Tâm Bất Biến',
        subtitle: '30 ngày tu luyện liên tục',
        progress: cultivation.streakDays,
        maxProgress: 30,
        isUnlocked: cultivation.streakDays >= 30,
      },
    ];

    return {
      user: {
        id: user.id,
        firebaseUid,
        email: user.email,
        displayName: user.display_name || name || 'Đạo Hữu Tiên Lộ',
        username: `@${username}`,
        avatarUrl: cleanAvatarUrl,
        joinedDate,
        rankBadge,
      },
      stats: {
        streakDays: cultivation.streakDays,
        completedQuests,
        totalExp: cultivation.totalExp,
        spiritStones: cultivation.spiritStones,
        goldCoins,
      },
      cultivationProgress: {
        currentRealmIndex: cultivation.realmIndex,
        realmName: cultivation.realmName,
        subRealm: cultivation.subRealm,
        currentTitle: cultivation.title,
        nextTitle,
        currentExp: cultivation.currentExp,
        maxExp: cultivation.maxExp,
        expNeeded,
        progressPercent,
      },
      featuredAchievements,
      allAchievements,
    };
  }

  async updateProfile(firebaseUid: string, dto: UpdateProfileDto) {
    const existing = await this.supabaseService.getUserByFirebaseUid(firebaseUid);
    let avatarUrl = dto.avatarUrl ?? existing?.avatar_url ?? null;
    if (avatarUrl && avatarUrl.includes('images.unsplash.com')) {
      avatarUrl = null;
    }

    if (!existing) {
      return this.supabaseService.upsertUser({
        firebase_uid: firebaseUid,
        email: `${firebaseUid}@tienlo.app`,
        display_name: dto.displayName,
        avatar_url: avatarUrl,
      });
    }

    return this.supabaseService.upsertUser({
      firebase_uid: firebaseUid,
      email: existing.email,
      display_name: dto.displayName ?? existing.display_name,
      avatar_url: avatarUrl,
    });
  }
}
