import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { SupabaseService } from '../database/supabase.service.js';
import { CultivationService } from '../cultivation/cultivation.service.js';
import { QuestDifficulty, DIFFICULTY_REWARDS } from '../cultivation/cultivation.constants.js';

export interface GeneratedQuest {
  id: string;
  campaignId: string;
  title: string;
  subtitle: string;
  difficulty: QuestDifficulty;
  expReward: number;
  stoneReward: number;
  iconType: string;
  isDaily: boolean;
  isCompleted: boolean;
  isXpClaimed: boolean;
}

export interface GeneratedCampaign {
  id: string;
  userId: string;
  title: string;
  goalPrompt: string;
  durationDays: number;
  status: string;
  quests: GeneratedQuest[];
  createdAt: string;
}

@Injectable()
export class CampaignsService {
  private readonly logger = new Logger(CampaignsService.name);
  private readonly inMemoryCampaigns = new Map<string, GeneratedCampaign[]>();
  private genAiClient: GoogleGenAI | null = null;

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly cultivationService: CultivationService,
  ) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (apiKey && apiKey.length > 10 && !apiKey.startsWith('your-')) {
      try {
        this.genAiClient = new GoogleGenAI({ apiKey });
        this.logger.log('Khởi tạo Gemini AI Client thành công cho Tiên Lộ!');
      } catch (err: any) {
        this.logger.warn(`Không thể khởi tạo Gemini AI Client: ${err.message}`);
      }
    } else {
      this.logger.warn(
        'GEMINI_API_KEY chưa cấu hình hoặc không hợp lệ. Sẽ sử dụng bộ diễn toán Tiên Lộ thông minh nội bộ.',
      );
    }
  }

  async generateAiCampaign(
    userId: string,
    goalPrompt: string,
    durationDays: number = 30,
  ): Promise<GeneratedCampaign> {
    const campaignId = `camp-${Date.now()}`;
    let campaignTitle = `Chiến Dịch: ${goalPrompt}`;
    let rawQuests: Array<{
      title: string;
      subtitle: string;
      difficulty: string;
      expReward?: number;
      stoneReward?: number;
      iconType?: string;
      isDaily?: boolean;
    }> = [];

    // 1. Thử gọi Gemini AI nếu có client
    if (this.genAiClient) {
      try {
        const prompt = `Bạn là "Thiên Đạo Trí Tuệ" của ứng dụng phát triển bản thân phong cách Tu Tiên RPG "Tiên Lộ".
Tu sĩ gửi mục tiêu rèn luyện đời thực: "${goalPrompt}" trong thời gian dự kiến ${durationDays} ngày.
Hãy phân tích mục tiêu thành một kế hoạch tu tiên sắc bén, thực tế và khả thi.
Tạo 3 đến 5 nhiệm vụ hàng ngày hoặc thử thách để tu sĩ thực hiện.

Quy định phần thưởng:
- EASY (Luyện Thể - Dễ): 50-100 Linh Lực (EXP), 5-10 Linh Thạch
- MEDIUM (Trúc Cơ - Vừa): 150-300 Linh Lực (EXP), 20-40 Linh Thạch
- HARD (Ngưng Đan - Khó): 400-800 Linh Lực (EXP), 50-100 Linh Thạch
- BREAKTHROUGH (Thiên Kiếp - Đại Thử Thách): 1500-3000 Linh Lực (EXP), 200-500 Linh Thạch

iconType chỉ chọn trong danh sách: "fitness", "water", "walk", "meditation", "study", "medal".

Trả về DUY NHẤT một JSON hợp lệ không có giải thích thêm, đúng cấu trúc sau:
{
  "campaignTitle": "Tên chiến dịch phong cách tiên hiệp hùng tráng",
  "quests": [
    {
      "title": "Tên hành động ngắn gọn",
      "subtitle": "Hướng dẫn cụ thể (vd: 3 hiệp · Cường độ vừa)",
      "difficulty": "EASY" | "MEDIUM" | "HARD" | "BREAKTHROUGH",
      "expReward": 200,
      "stoneReward": 25,
      "iconType": "fitness",
      "isDaily": true
    }
  ]
}`;

        const response = await this.genAiClient.models.generateContent({
          model: 'gemini-2.5-flash',
          contents: prompt,
          config: {
            responseMimeType: 'application/json',
          },
        });

        const text = response.text?.trim() || '';
        const parsed = JSON.parse(text);
        if (parsed.campaignTitle) campaignTitle = parsed.campaignTitle;
        if (Array.isArray(parsed.quests) && parsed.quests.length > 0) {
          rawQuests = parsed.quests;
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi khi gọi Gemini AI: ${err.message}. Chuyển sang quy tắc nội bộ.`);
      }
    }

    // 2. Fallback sang bộ quy tắc thông minh nếu AI không khả dụng hoặc lỗi JSON
    if (rawQuests.length === 0) {
      rawQuests = this.generateFallbackQuests(goalPrompt);
      campaignTitle = `Tu Tiên Luyện Thể: ${goalPrompt}`;
    }

    // 3. Chuẩn hóa danh sách Quests
    const quests: GeneratedQuest[] = rawQuests.map((q, idx) => {
      let diff = QuestDifficulty.MEDIUM;
      if (q.difficulty === 'EASY') diff = QuestDifficulty.EASY;
      else if (q.difficulty === 'HARD') diff = QuestDifficulty.HARD;
      else if (q.difficulty === 'BREAKTHROUGH') diff = QuestDifficulty.BREAKTHROUGH;

      const rewardTier = DIFFICULTY_REWARDS[diff];
      const expReward = q.expReward || rewardTier.minExp;
      const stoneReward = q.stoneReward || rewardTier.minStones;

      return {
        id: `q-${Date.now()}-${idx}`,
        campaignId,
        title: q.title,
        subtitle: q.subtitle || `${rewardTier.label} · Hàng ngày`,
        difficulty: diff,
        expReward,
        stoneReward,
        iconType: q.iconType || 'fitness',
        isDaily: q.isDaily !== false,
        isCompleted: false,
        isXpClaimed: false,
      };
    });

    const campaign: GeneratedCampaign = {
      id: campaignId,
      userId,
      title: campaignTitle,
      goalPrompt,
      durationDays,
      status: 'ACTIVE',
      quests,
      createdAt: new Date().toISOString(),
    };

    // 4. Lưu vào Supabase hoặc in-memory
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        await client.from('campaigns').insert({
          id: campaign.id,
          user_id: userId,
          title: campaign.title,
          goal_prompt: goalPrompt,
          duration_days: durationDays,
          status: 'ACTIVE',
        });

        for (const q of quests) {
          await client.from('quests').insert({
            id: q.id,
            campaign_id: campaign.id,
            user_id: userId,
            title: q.title,
            subtitle: q.subtitle,
            difficulty: q.difficulty,
            exp_reward: q.expReward,
            stone_reward: q.stoneReward,
            icon_type: q.iconType,
            is_daily: q.isDaily,
            is_completed: false,
            is_xp_claimed: false,
          });
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi lưu Supabase campaigns: ${err.message}`);
      }
    }

    const userCamps = this.inMemoryCampaigns.get(userId) || [];
    userCamps.unshift(campaign);
    this.inMemoryCampaigns.set(userId, userCamps);

    return campaign;
  }

  async getUserCampaigns(userId: string): Promise<GeneratedCampaign[]> {
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        const { data: camps } = await client
          .from('campaigns')
          .select('*, quests(*)')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (camps && camps.length > 0) {
          return camps.map((c: any) => ({
            id: c.id,
            userId: c.user_id,
            title: c.title,
            goalPrompt: c.goal_prompt,
            durationDays: c.duration_days,
            status: c.status,
            createdAt: c.created_at,
            quests: (c.quests || []).map((q: any) => ({
              id: q.id,
              campaignId: q.campaign_id,
              title: q.title,
              subtitle: q.subtitle,
              difficulty: q.difficulty as QuestDifficulty,
              expReward: q.exp_reward,
              stoneReward: q.stone_reward,
              iconType: q.icon_type,
              isDaily: q.is_daily,
              isCompleted: q.is_completed,
              isXpClaimed: q.is_xp_claimed,
            })),
          }));
        }
      } catch (_) {}
    }

    return this.inMemoryCampaigns.get(userId) || [];
  }

  async completeQuest(
    userId: string,
    questId: string,
  ): Promise<{
    questId: string;
    expAwarded: number;
    stonesAwarded: number;
    cultivation: any;
  }> {
    let targetQuest: GeneratedQuest | null = null;

    // Tìm trong in-memory
    const userCamps = this.inMemoryCampaigns.get(userId) || [];
    for (const c of userCamps) {
      const q = c.quests.find((item) => item.id === questId);
      if (q) {
        targetQuest = q;
        q.isCompleted = true;
        q.isXpClaimed = true;
        break;
      }
    }

    const expAwarded = targetQuest?.expReward || 150;
    const stonesAwarded = targetQuest?.stoneReward || 20;

    // Cộng Linh Lực & Linh Thạch qua CultivationService
    const expResult = await this.cultivationService.addExp(userId, expAwarded);
    const stonesResult = await this.cultivationService.addSpiritStones(
      userId,
      stonesAwarded,
      `Thưởng hoàn thành nhiệm vụ: ${targetQuest?.title || questId}`,
    );

    // Cập nhật Supabase
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        await client
          .from('quests')
          .update({
            is_completed: true,
            is_xp_claimed: true,
            completed_at: new Date().toISOString(),
          })
          .eq('id', questId);
      } catch (_) {}
    }

    return {
      questId,
      expAwarded,
      stonesAwarded,
      cultivation: stonesResult,
    };
  }

  private generateFallbackQuests(prompt: string): Array<{
    title: string;
    subtitle: string;
    difficulty: string;
    expReward: number;
    stoneReward: number;
    iconType: string;
    isDaily: boolean;
  }> {
    const isFitness = /cơ|bụng|múi|gym|chạy|thể dục|cân|nặng|workout/i.test(prompt);

    if (isFitness) {
      return [
        {
          title: 'Tập Core & Plank 15 phút',
          subtitle: '3 hiệp · Cường độ vừa',
          difficulty: 'MEDIUM',
          expReward: 200,
          stoneReward: 25,
          iconType: 'fitness',
          isDaily: true,
        },
        {
          title: 'Uống đủ 2L nước thanh lọc thể',
          subtitle: 'Bổ sung nước suốt cả ngày',
          difficulty: 'EASY',
          expReward: 80,
          stoneReward: 10,
          iconType: 'water',
          isDaily: true,
        },
        {
          title: 'Đi bộ hoặc chạy 5.000 bước',
          subtitle: 'Vận động đốt mỡ nhẹ',
          difficulty: 'MEDIUM',
          expReward: 160,
          stoneReward: 20,
          iconType: 'walk',
          isDaily: true,
        },
        {
          title: 'Đại Thử Thách: Hoàn thành 1 tuần không ăn vặt',
          subtitle: 'Thiên Kiếp Thử Thách · Đốt mỡ tối đa',
          difficulty: 'BREAKTHROUGH',
          expReward: 1800,
          stoneReward: 250,
          iconType: 'medal',
          isDaily: false,
        },
      ];
    }

    return [
      {
        title: `Rèn luyện: ${prompt.slice(0, 30)}`,
        subtitle: 'Khởi đầu ngày mới tập trung 25 phút',
        difficulty: 'MEDIUM',
        expReward: 180,
        stoneReward: 20,
        iconType: 'study',
        isDaily: true,
      },
      {
        title: 'Tịnh tâm thiền định 10 phút',
        subtitle: 'Thanh lọc tạp niệm trước khi tu luyện',
        difficulty: 'EASY',
        expReward: 75,
        stoneReward: 10,
        iconType: 'meditation',
        isDaily: true,
      },
      {
        title: 'Độ Kiếp: Tổng kết kết quả sau 7 ngày',
        subtitle: 'Đánh giá chỉ số tiến bộ',
        difficulty: 'HARD',
        expReward: 600,
        stoneReward: 80,
        iconType: 'medal',
        isDaily: false,
      },
    ];
  }
}
