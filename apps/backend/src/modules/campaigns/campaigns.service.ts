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

  private extractDurationDays(goalPrompt: string, defaultDays: number = 14): number {
    const lower = goalPrompt.toLowerCase();
    if (lower.includes('nửa tháng') || lower.includes('nua thang')) return 15;
    if (lower.includes('một tháng') || lower.includes('mot thang')) return 30;
    if (lower.includes('hai tháng') || lower.includes('hai thang')) return 60;
    if (lower.includes('ba tháng') || lower.includes('ba thang')) return 90;
    if (lower.includes('một tuần') || lower.includes('mot tuan')) return 7;
    if (lower.includes('hai tuần') || lower.includes('hai tuan')) return 14;
    if (lower.includes('ba tuần') || lower.includes('ba tuan')) return 21;
    if (lower.includes('bốn tuần') || lower.includes('bon tuan')) return 28;

    const weekMatch = lower.match(/(\d+)\s*(tuần|tuan)/);
    if (weekMatch) return parseInt(weekMatch[1], 10) * 7;
    const monthMatch = lower.match(/(\d+)\s*(tháng|thang)/);
    if (monthMatch) return parseInt(monthMatch[1], 10) * 30;
    const dayMatch = lower.match(/(\d+)\s*(ngày|ngay|ng)/);
    if (dayMatch) return parseInt(dayMatch[1], 10);
    return defaultDays;
  }

  async generateAiCampaign(
    userId: string,
    goalPrompt: string,
    durationDays: number = 14,
  ): Promise<GeneratedCampaign> {
    const campaignId = `camp-${Date.now()}`;
    const calculatedDuration = this.extractDurationDays(goalPrompt, durationDays);
    let finalDuration = calculatedDuration;
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
Tu sĩ gửi mục tiêu rèn luyện đời thực: "${goalPrompt}".
Thời gian chiến dịch được xác định là ${calculatedDuration} ngày (ví dụ: '2 tuần' = 14 ngày, '3 tháng' = 90 ngày).
Chiến dịch sẽ duy trì liên tục trong suốt ${calculatedDuration} ngày. MỖI NGÀY tu sĩ sẽ có đúng 3 NHIỆM VỤ HÀNG NGÀY cần hoàn thành:
1. Nhiệm vụ 1: Độ khó EASY (DỄ) - Dinh dưỡng, nước uống hoặc thói quen nền tảng
2. Nhiệm vụ 2: Độ khó MEDIUM (VỪA) - Bài tập chính hoặc hành động trọng tâm hôm nay
3. Nhiệm vụ 3: Độ khó HARD (KHÓ) - Thử thách bứt phá hoặc kỷ luật nâng cao

Quy định phần thưởng:
- EASY (Dễ): 80-120 Linh Lực (EXP), 10-15 Nguyên Thạch
- MEDIUM (Vừa): 150-250 Linh Lực (EXP), 20-30 Nguyên Thạch
- HARD (Khó): 300-500 Linh Lực (EXP), 40-60 Nguyên Thạch

LƯU Ý QUAN TRỌNG:
- Độ khó ("difficulty") CHỈ được là một trong 3 giá trị: "EASY", "MEDIUM", "HARD". Tuyệt đối KHÔNG ghi cảnh giới tu tiên như Trúc Cơ, Luyện Thể vào độ khó hay phụ đề.
- Mỗi ngày đúng 3 nhiệm vụ.
- iconType chỉ chọn trong danh sách: "fitness", "water", "walk", "meditation", "study", "medal".

Trả về DUY NHẤT một JSON hợp lệ không có giải thích thêm, đúng cấu trúc sau:
{
  "campaignTitle": "Tên chiến dịch phong cách tiên hiệp hùng tráng",
  "durationDays": ${calculatedDuration},
  "quests": [
    {
      "title": "Tên hành động ngắn gọn",
      "subtitle": "Hướng dẫn cụ thể cho ngày rèn luyện",
      "difficulty": "EASY" | "MEDIUM" | "HARD",
      "expReward": 100,
      "stoneReward": 15,
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
        if (parsed.durationDays && typeof parsed.durationDays === 'number') {
          finalDuration = parsed.durationDays;
        }
        if (Array.isArray(parsed.quests) && parsed.quests.length > 0) {
          rawQuests = parsed.quests.slice(0, 3);
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi khi gọi Gemini AI: ${err.message}. Chuyển sang quy tắc nội bộ.`);
      }
    }

    // 2. Fallback sang bộ quy tắc thông minh nếu AI không khả dụng hoặc lỗi JSON
    if (rawQuests.length === 0) {
      rawQuests = this.generateFallbackQuests(goalPrompt);
      campaignTitle = `Tiên Lộ Tu Thân: ${goalPrompt}`;
    }

    // 3. Chuẩn hóa danh sách Quests (luôn đảm bảo 3 nhiệm vụ mỗi ngày)
    const quests: GeneratedQuest[] = rawQuests.slice(0, 3).map((q, idx) => {
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
        subtitle: q.subtitle || 'Rèn luyện hàng ngày',
        difficulty: diff,
        expReward,
        stoneReward,
        iconType: q.iconType || 'fitness',
        isDaily: true,
        isCompleted: false,
        isXpClaimed: false,
      };
    });

    const campaign: GeneratedCampaign = {
      id: campaignId,
      userId,
      title: campaignTitle,
      goalPrompt,
      durationDays: finalDuration,
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
    const lower = prompt.toLowerCase();
    const isWeightGain = /tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân/i.test(lower);
    const isFitness = /cơ|bụng|múi|gym|chạy|thể dục|cân|nặng|workout|mỡ|giảm/i.test(lower);
    const isStudy = /học|đọc|sách|code|lập trình|thi|tiếng anh|nghiên cứu/i.test(lower);

    if (isWeightGain) {
      return [
        {
          title: 'Nạp 4-5 bữa ăn giàu dinh dưỡng',
          subtitle: 'Bổ sung thặng dư calo, protein và tinh bột tốt suốt cả ngày',
          difficulty: 'EASY',
          expReward: 100,
          stoneReward: 15,
          iconType: 'fitness',
          isDaily: true,
        },
        {
          title: 'Tập tạ kích thích cơ bắp 30 phút',
          subtitle: 'Tập các bài Compound (Squat, Deadlift) gia tăng đồng hóa',
          difficulty: 'MEDIUM',
          expReward: 220,
          stoneReward: 25,
          iconType: 'fitness',
          isDaily: true,
        },
        {
          title: 'Uống sinh tố dinh dưỡng & ngủ đủ 8 tiếng',
          subtitle: 'Tối ưu quá trình hấp thu và tái tạo cơ bắp ban đêm',
          difficulty: 'HARD',
          expReward: 350,
          stoneReward: 40,
          iconType: 'medal',
          isDaily: true,
        },
      ];
    }

    if (isFitness) {
      return [
        {
          title: 'Uống đủ 2L nước lọc & hạn chế tối đa đường',
          subtitle: 'Thanh lọc cơ thể, hỗ trợ chuyển hóa mỡ thừa',
          difficulty: 'EASY',
          expReward: 80,
          stoneReward: 10,
          iconType: 'water',
          isDaily: true,
        },
        {
          title: 'Tập gập bụng & Plank 15 phút',
          subtitle: '3 hiệp Plank & Crunch kích hoạt cơ múi bụng',
          difficulty: 'MEDIUM',
          expReward: 200,
          stoneReward: 25,
          iconType: 'fitness',
          isDaily: true,
        },
        {
          title: 'Cardio hoặc chạy bộ 20 phút đốt mỡ',
          subtitle: 'Duy trì nhịp tim đốt calo thâm hụt sau buổi tập',
          difficulty: 'HARD',
          expReward: 350,
          stoneReward: 40,
          iconType: 'walk',
          isDaily: true,
        },
      ];
    }

    if (isStudy) {
      return [
        {
          title: 'Đọc sách hoặc tài liệu 20 phút',
          subtitle: 'Khởi động tư duy mỗi sáng bằng tri thức mới',
          difficulty: 'EASY',
          expReward: 80,
          stoneReward: 10,
          iconType: 'study',
          isDaily: true,
        },
        {
          title: 'Tập trung học sâu 45 phút Pomodoro',
          subtitle: 'Tuyệt đối không lướt mạng xã hội, tập trung cao độ',
          difficulty: 'MEDIUM',
          expReward: 200,
          stoneReward: 25,
          iconType: 'study',
          isDaily: true,
        },
        {
          title: 'Thực hành làm bài tập hoặc viết code 30 phút',
          subtitle: 'Ứng dụng trực tiếp kiến thức vừa học vào thực tế',
          difficulty: 'HARD',
          expReward: 350,
          stoneReward: 40,
          iconType: 'medal',
          isDaily: true,
        },
      ];
    }

    return [
      {
        title: 'Hành động nhỏ khởi đầu ngày mới',
        subtitle: 'Dành 20 phút hành động kiên trì cho mục tiêu',
        difficulty: 'EASY',
        expReward: 80,
        stoneReward: 10,
        iconType: 'study',
        isDaily: true,
      },
      {
        title: 'Thực hiện cam kết rèn luyện hôm nay',
        subtitle: 'Tập trung hoàn thành chỉ tiêu đề ra',
        difficulty: 'MEDIUM',
        expReward: 200,
        stoneReward: 25,
        iconType: 'fitness',
        isDaily: true,
      },
      {
        title: 'Thử thách bứt phá giới hạn',
        subtitle: 'Nâng cao cường độ rèn luyện trong ngày',
        difficulty: 'HARD',
        expReward: 350,
        stoneReward: 40,
        iconType: 'medal',
        isDaily: true,
      },
    ];
  }
}
