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

        let response: any;
        try {
          response = await this.genAiClient.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
            config: {
              responseMimeType: 'application/json',
            },
          });
        } catch (_) {
          try {
            response = await this.genAiClient.models.generateContent({
              model: 'gemini-2.0-flash',
              contents: prompt,
              config: {
                responseMimeType: 'application/json',
              },
            });
          } catch (__) {
            response = await this.genAiClient.models.generateContent({
              model: 'gemini-1.5-flash',
              contents: prompt,
              config: {
                responseMimeType: 'application/json',
              },
            });
          }
        }

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

  private readonly statsAiCache = new Map<string, { data: any; timestamp: number }>();

  async getStatistics(userId: string) {
    const profile = await this.cultivationService.getProfile(userId);
    const userCamps = await this.getUserCampaigns(userId);

    const activeCamp = userCamps[0] || null;
    const activeCampaignTitle = activeCamp?.title || 'Kiến Tạo Phiên Bản 2.0';
    const campaignTotalDays = activeCamp?.durationDays || 14;

    let campaignCurrentDay = 1;
    if (activeCamp?.createdAt) {
      try {
        const start = new Date(activeCamp.createdAt);
        const now = new Date();
        const diffDays = Math.floor((now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
        campaignCurrentDay = Math.min(Math.max(1, diffDays + 1), campaignTotalDays);
      } catch (_) {}
    }

    const campaignProgress = Math.min(1.0, campaignCurrentDay / campaignTotalDays);
    const stageIndex = Math.min(3, Math.floor(campaignProgress * 4));
    const stages = ['Khởi động', 'Nền tảng', 'Đột phá', 'Duy trì'];
    const stageName = stages[stageIndex];

    const activeQuests = activeCamp?.quests || [];
    const completedQuestsCount = activeQuests.filter((q) => q.isCompleted || q.isXpClaimed).length;
    const totalQuestsCount = activeQuests.length || 3;
    const completionRate = totalQuestsCount > 0 ? Math.round((completedQuestsCount / totalQuestsCount) * 100) : 85;
    const currentWeek = Math.floor((campaignCurrentDay - 1) / 7) + 1;
    const totalWeeks = Math.max(1, Math.ceil(campaignTotalDays / 7));
    const completedQuestsTotal = Math.max(completedQuestsCount, (campaignCurrentDay - 1) * 3 + completedQuestsCount);
    const totalPlannedQuests = campaignTotalDays * 3;

    // Check AI cache (10 minutes)
    const cacheKey = `${userId}_${activeCampaignTitle}_${profile.streakDays}`;
    const cached = this.statsAiCache.get(cacheKey);
    let aiEvaluation: any = null;

    if (cached && Date.now() - cached.timestamp < 10 * 60 * 1000) {
      aiEvaluation = cached.data;
    }

    // Call Gemini AI if available and not cached
    if (!aiEvaluation && this.genAiClient) {
      try {
        const prompt = `Bạn là "Thiên Đạo AI" trong hệ thống tu chân hiện đại Tiên Lộ (Gamified Habit & Self-Improvement App).
Hãy phân tích dữ liệu tu luyện sau của Đạo hữu để đánh giá căn cốt năng lực đời thực và đưa ra lời khuyên:
- Cảnh giới: ${profile.realmName} Tầng ${profile.subRealm}
- Chuỗi ngày tu luyện: ${profile.streakDays} ngày
- Linh lực EXP: ${profile.currentExp}/${profile.maxExp}
- Mục tiêu/Chiến dịch hiện tại: "${activeCampaignTitle}" (Ngày ${campaignCurrentDay}/${campaignTotalDays}, Chặng: ${stageName})
- Các nhiệm vụ tu luyện: ${activeQuests.map((q) => q.title).join('; ') || 'Rèn luyện thân thể, đọc sách, định tâm'}

Hãy trả về JSON theo đúng định dạng sau (chỉ JSON thuần túy, không có markdown formatting hay chú thích):
{
  "attributes": {
    "physical": <số nguyên từ 30 đến 95, tỉ lệ % Thể chất>,
    "intellect": <số nguyên từ 30 đến 95, tỉ lệ % Trí thức>,
    "focus": <số nguyên từ 30 đến 95, tỉ lệ % Định lực / Tập trung>,
    "social": <số nguyên từ 20 đến 90, tỉ lệ % Giao tiếp / Tâm thái>
  },
  "aiIntelligence": {
    "tag": "WEEKLY INTELLIGENCE • THIÊN ĐẠO AI",
    "bestTime": "6–8h sáng",
    "title": "<1 câu tiêu đề đúc kết nhận xét từ AI, ví dụ: 'Bạn làm quest tốt nhất lúc 6–8h sáng' hoặc 'Căn cốt Thể chất bứt phá ngoạn mục'>",
    "advice": "<2-3 câu lời bình sâu sắc, uyên bác theo phong cách Tiên Hiệp kết hợp phát triển bản thân, chỉ ra điểm mạnh và điểm cần cải thiện>",
    "growthTrend": "+12% tuần này"
  },
  "weeklyActivity": [<7 số nguyên từ 0 đến 3 biểu thị số quest hoàn thành các ngày T2, T3, T4, T5, T6, T7, CN>]
}`;

        let response: any;
        try {
          response = await this.genAiClient.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
            config: { responseMimeType: 'application/json' },
          });
        } catch (_) {
          try {
            response = await this.genAiClient.models.generateContent({
              model: 'gemini-2.0-flash',
              contents: prompt,
              config: { responseMimeType: 'application/json' },
            });
          } catch (__) {
            response = await this.genAiClient.models.generateContent({
              model: 'gemini-1.5-flash',
              contents: prompt,
              config: { responseMimeType: 'application/json' },
            });
          }
        }

        const text = response.text?.trim() || '';
        aiEvaluation = JSON.parse(text);
        this.statsAiCache.set(cacheKey, { data: aiEvaluation, timestamp: Date.now() });
      } catch (err: any) {
        this.logger.warn(`Lỗi khi AI phân tích thống kê: ${err.message}. Sử dụng bộ quy tắc nội bộ.`);
      }
    }

    // Dynamic smart fallback if AI unavailable
    if (!aiEvaluation) {
      const lower = activeCampaignTitle.toLowerCase();
      const isFitness = /cơ|bụng|múi|gym|chạy|thể dục|cân|nặng|workout|mỡ|giảm|tăng cân/i.test(lower);
      const isStudy = /học|đọc|sách|code|lập trình|thi|tiếng anh|nghiên cứu/i.test(lower);

      let physical = 75;
      let intellect = 65;
      let focus = 70;
      let social = 40;
      let bestTime = '6–8h sáng';
      let title = 'Bạn làm quest tốt nhất lúc 6–8h sáng';
      let advice = 'Sự kiên trì rèn luyện đang phát huy tác dụng. EXP tích lũy đều đặn, hãy cân bằng thêm các hoạt động giao tiếp và tĩnh tâm!';

      if (isFitness) {
        physical = 84;
        intellect = 62;
        focus = 73;
        social = 38;
        bestTime = '6–8h sáng';
        title = 'Căn cốt Thể chất tăng tiến vượt bậc';
        advice = 'Thiên Đạo nhận thấy đạo hữu rất chăm chỉ luyện thể. Hãy bổ sung dinh dưỡng và nghỉ ngơi hợp lý để cơ bắp phục hồi tối ưu!';
      } else if (isStudy) {
        physical = 50;
        intellect = 88;
        focus = 82;
        social = 45;
        bestTime = '20–22h tối';
        title = 'Đạo hữu tập trung cao độ vào buổi tối';
        advice = 'Trí thức và Định lực khai mở rất nhanh. Đừng quên vận động thể chất nhẹ nhàng để khí huyết lưu thông, tránh bế tắc kinh mạch!';
      }

      aiEvaluation = {
        attributes: { physical, intellect, focus, social },
        aiIntelligence: {
          tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
          bestTime,
          title,
          advice,
          growthTrend: '+12% tuần này',
        },
        weeklyActivity: [3, 2, 3, 3, 2, 3, completedQuestsCount || 1],
      };
    }

    return {
      activeCampaignTitle,
      campaignCurrentDay,
      campaignTotalDays,
      completedQuests: completedQuestsTotal,
      totalPlannedQuests,
      completionRate,
      currentWeek,
      totalWeeks,
      stageIndex,
      stageName,
      metrics: {
        streakDays: profile.streakDays,
        currentExp: profile.currentExp,
        maxExp: profile.maxExp,
        spiritStones: profile.spiritStones,
        realmName: profile.realmName,
        subRealm: profile.subRealm,
      },
      attributes: aiEvaluation.attributes || { physical: 80, intellect: 65, focus: 70, social: 40 },
      weeklyActivity: aiEvaluation.weeklyActivity || [3, 2, 3, 3, 2, 3, 1],
      aiIntelligence: aiEvaluation.aiIntelligence || {
        tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
        title: 'Bạn làm quest tốt nhất lúc 6–8h sáng',
        advice: 'Thiên Đạo ghi nhận sự kiên trì của đạo hữu. Hãy giữ vững nhịp độ này!',
        bestTime: '6–8h sáng',
        growthTrend: '+12% tuần này',
      },
    };
  }
}

