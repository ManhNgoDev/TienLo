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
        const prompt = `Bạn là "HỆ THỐNG SOLO LEVELING" (Giao diện ban bố Nhiệm Vụ Hàng Ngày - Daily Quests phong cách Thợ Săn Thăng Cấp Một Mình kết hợp Tiên Lộ Tu Thân).
Người chơi (Người Thức Tỉnh) thiết lập mục tiêu rèn luyện đời thực: "${goalPrompt}".
Thời gian chiến dịch được xác định là ${calculatedDuration} ngày (ví dụ: '2 tuần' = 14 ngày, '3 tháng' = 90 ngày).
Chiến dịch duy trì liên tục trong suốt ${calculatedDuration} ngày. MỖI NGÀY người chơi BẮT BUỘC có đúng 3 NHIỆM VỤ HÀNG NGÀY (Daily Quests).

YÊU CẦU CỐT LÕI VỀ NHIỆM VỤ (CHUẨN HỆ THỐNG SOLO LEVELING):
1. TUYỆT ĐỐI CẤM các câu khẩu hiệu chung chung, mơ hồ, sáo rỗng hoặc khuyên bảo đạo lý như: "Hoạt động chăm chỉ", "Hành động kiên trì", "Cố gắng nỗ lực", "Thực hiện cam kết", "Suy nghĩ tích cực", "Hành động nhỏ khởi đầu"...
2. TẤT CẢ CÁC NHIỆM VỤ ĐỀU PHẢI LÀ HÀNH ĐỘNG VẬT LÝ / THỰC HÀNH CỤ THỂ, BẮT BUỘC CÓ CON SỐ ĐỊNH LƯỢNG RÕ RÀNG (Số cái/reps, số hiệp/sets, số km, số phút, số lít nước):
   - Với mục tiêu thể chất / sức khỏe / tăng cơ / giảm mỡ / vóc dáng (Chuẩn Solo Leveling Daily Quest):
     * Chống đẩy (Push-ups): [Chống đẩy 50 cái], [Chống đẩy 70 cái], hoặc [Chống đẩy 100 cái]
     * Gập bụng (Sit-ups) / Plank: [Gập bụng 60 cái], [Gập bụng 100 cái], hoặc [Plank 3 phút]
     * Đứng lên ngồi xuống (Squats): [Squat 60 cái], [Squat 80 cái], hoặc [Squat 100 cái]
     * Chạy bộ (Running): [Chạy bộ 3km], [Chạy bộ 5km], hoặc [Chạy bộ 10km]
     * Bổ trợ: [Kéo xà đơn 15 cái], [Nhảy dây 300 cái], [Uống đủ 2L - 2.5L nước lọc]
   - Với mục tiêu học tập / công việc / kỹ năng (nếu người chơi yêu cầu đọc sách, code, thi cử):
     * [Tập trung sâu Pomodoro 45 phút] (không dùng điện thoại/mạng xã hội)
     * [Đọc 25 trang sách chuyên môn]
     * [Viết 50 dòng code / Giải 2 bài tập thuật toán]
3. Phân bổ chính xác 3 cấp độ nhiệm vụ mỗi ngày:
   - Nhiệm vụ 1: Độ khó EASY (DỄ) - Thể lực khởi động hoặc dinh dưỡng/nền tảng có định lượng cụ thể (VD: Uống đủ 2L nước lọc, Chống đẩy 30 cái, hoặc Giãn cơ 15 phút). Thưởng: 80-120 Linh Lực (EXP), 10-15 Nguyên Thạch.
   - Nhiệm vụ 2: Độ khó MEDIUM (VỪA) - Bài tập thể lực trọng tâm Solo Leveling (VD: Chống đẩy 60 cái, Gập bụng 70 cái, Squat 80 cái, hoặc Học Pomodoro 45 phút). Thưởng: 150-250 Linh Lực (EXP), 20-30 Nguyên Thạch.
   - Nhiệm vụ 3: Độ khó HARD (KHÓ) - Thử thách cực hạn bứt phá ngưỡng chịu đựng Solo Leveling (VD: Chạy bộ 3km - 5km không dừng, hoặc Chống đẩy 100 cái chia hiệp). Thưởng: 300-500 Linh Lực (EXP), 40-60 Nguyên Thạch.

QUY TẮC ĐỊNH DẠNG:
- "campaignTitle": Tiêu đề chiến dịch đậm chất Hệ Thống Solo Leveling / Thăng Cấp (Ví dụ: "[HỆ THỐNG] Nhiệm Vụ Hàng Ngày: Chuẩn Bị Để Trở Nên Mạnh Mẽ", "[HỆ THỐNG] Thăng Cấp Thể Chất ${calculatedDuration} Ngày", v.v.).
- "title": Bắt buộc chứa ĐỘNG TÁC + CON SỐ CỤ THỂ. Ví dụ: "Chống đẩy 50 cái", "Gập bụng 60 cái", "Chạy bộ 3km", "Squat 80 cái", "Uống đủ 2L nước lọc".
- "subtitle": Hướng dẫn kỹ thuật/chia hiệp nghiêm khắc, mang phong cách Hệ Thống (ví dụ: "Chia 3-4 hiệp, ngực sát đất, nghỉ 60s giữa hiệp. Không hoàn thành sẽ bị xử phạt!", "Duy trì nhịp chạy đều đặn không đi bộ").
- "difficulty": CHỈ được là một trong 3 giá trị: "EASY", "MEDIUM", "HARD". Tuyệt đối không dùng từ khác.
- "iconType": Chọn chuẩn xác một trong các giá trị: "fitness", "water", "walk", "meditation", "study", "medal".
- Trả về đúng 3 nhiệm vụ.

Trả về DUY NHẤT một JSON hợp lệ không có giải thích thêm, đúng cấu trúc sau:
{
  "campaignTitle": "[HỆ THỐNG] Nhiệm Vụ Hàng Ngày: Thăng Cấp Thể Chất",
  "durationDays": ${calculatedDuration},
  "quests": [
    {
      "title": "Chống đẩy 50 cái",
      "subtitle": "Chia 3-4 hiệp, ngực sát đất chuẩn form, nghỉ 60s giữa hiệp. Không hoàn thành sẽ nhận hình phạt!",
      "difficulty": "MEDIUM",
      "expReward": 200,
      "stoneReward": 25,
      "iconType": "fitness",
      "isDaily": true
    }
  ]
}`;

        const candidateModels = [
          'gemini-3.5-flash-lite',
          'gemini-3.8-flash',
          'gemini-3.5-flash',
          'gemini-flash-latest',
        ];

        let response: any;
        for (const model of candidateModels) {
          try {
            response = await this.genAiClient.models.generateContent({
              model,
              contents: prompt,
              config: {
                responseMimeType: 'application/json',
              },
            });
            if (response?.text) break;
          } catch (modelErr: any) {
            this.logger.debug(`Model ${model} không khả dụng: ${modelErr.message}`);
          }
        }

        const text = response?.text?.trim() || '';
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
      campaignTitle = `[HỆ THỐNG] Nhiệm Vụ Hàng Ngày: ${goalPrompt}`;
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
    allCompleted?: boolean;
    streakIncremented?: boolean;
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
    await this.cultivationService.addSpiritStones(
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

    // Kiểm tra xem tất cả nhiệm vụ trong chiến dịch hôm nay đã hoàn thành chưa
    let allCompleted = false;
    let streakIncremented = false;

    for (const c of userCamps) {
      if (c.quests.some((item) => item.id === questId)) {
        if (c.quests.length > 0 && c.quests.every((q) => q.isCompleted || q.isXpClaimed)) {
          allCompleted = true;
        }
        break;
      }
    }

    if (client && !allCompleted) {
      try {
        const { data: questData } = await client
          .from('quests')
          .select('campaign_id')
          .eq('id', questId)
          .maybeSingle();

        if (questData?.campaign_id) {
          const { data: siblingQuests } = await client
            .from('quests')
            .select('is_completed')
            .eq('campaign_id', questData.campaign_id);

          if (
            siblingQuests &&
            siblingQuests.length > 0 &&
            siblingQuests.every((q: any) => q.is_completed)
          ) {
            allCompleted = true;
          }
        }
      } catch (_) {}
    }

    let finalCultivationState = expResult.profile;
    if (allCompleted) {
      const streakRes = await this.cultivationService.incrementStreakIfEligible(userId);
      if (streakRes.streakIncremented) {
        streakIncremented = true;
        finalCultivationState = streakRes.profile;
      }
    }

    return {
      questId,
      expAwarded,
      stonesAwarded,
      allCompleted,
      streakIncremented,
      cultivation: finalCultivationState,
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
    const isStudy = /học|đọc|sách|code|lập trình|thi|tiếng anh|nghiên cứu/i.test(lower);

    if (isWeightGain) {
      return [
        {
          title: 'Uống đủ 2.5L nước & nạp 4 bữa đủ đạm',
          subtitle: 'Duy trì thặng dư calo và đồng hóa cơ bắp liên tục suốt cả ngày',
          difficulty: 'EASY',
          expReward: 100,
          stoneReward: 15,
          iconType: 'water',
          isDaily: true,
        },
        {
          title: 'Squat 80 cái & Chống đẩy 50 cái',
          subtitle: 'Chia làm 4 hiệp chuẩn form, nghỉ 60s giữa hiệp. Kích hoạt phát triển cơ bắp!',
          difficulty: 'MEDIUM',
          expReward: 220,
          stoneReward: 25,
          iconType: 'fitness',
          isDaily: true,
        },
        {
          title: 'Kéo xà 20 cái & Ngủ đủ 8 tiếng',
          subtitle: 'Kéo xà chia 3-4 hiệp và đi ngủ trước 23h để tối ưu tái tạo thể lực',
          difficulty: 'HARD',
          expReward: 350,
          stoneReward: 40,
          iconType: 'medal',
          isDaily: true,
        },
      ];
    }

    if (isStudy) {
      return [
        {
          title: 'Đọc chính xác 25 trang sách',
          subtitle: 'Ghi chép 3 bài học đúc kết quan trọng, không đọc lướt',
          difficulty: 'EASY',
          expReward: 80,
          stoneReward: 10,
          iconType: 'study',
          isDaily: true,
        },
        {
          title: 'Tập trung học sâu Pomodoro 45 phút',
          subtitle: 'Tuyệt đối ngắt mạng xã hội, tập trung 100% công suất não bộ',
          difficulty: 'MEDIUM',
          expReward: 200,
          stoneReward: 25,
          iconType: 'study',
          isDaily: true,
        },
        {
          title: 'Thực hành giải 2 bài tập hoặc viết 50 dòng code',
          subtitle: 'Áp dụng trực tiếp vào sản phẩm thực tế, nghiệm thu bài làm hôm nay',
          difficulty: 'HARD',
          expReward: 350,
          stoneReward: 40,
          iconType: 'medal',
          isDaily: true,
        },
      ];
    }

    // Mặc định chuẩn Nhiệm Vụ Hàng Ngày Solo Leveling (Push-ups, Sit-ups, Squats, Running)
    return [
      {
        title: 'Uống đủ 2L nước lọc',
        subtitle: 'Bổ sung đều đặn trong ngày, thanh lọc cơ thể chuẩn bị thăng cấp',
        difficulty: 'EASY',
        expReward: 100,
        stoneReward: 15,
        iconType: 'water',
        isDaily: true,
      },
      {
        title: 'Chống đẩy 50 cái & Gập bụng 50 cái',
        subtitle: 'Chia làm 3-4 hiệp chạm ngực chuẩn form, nghỉ 60s. Không hoàn thành sẽ bị xử phạt!',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 25,
        iconType: 'fitness',
        isDaily: true,
      },
      {
        title: 'Chạy bộ 3km hoặc Squat 100 cái',
        subtitle: 'Duy trì nhịp chạy đều đặn không dừng lại, bứt phá giới hạn như Sung Jin-woo',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'walk',
        isDaily: true,
      },
    ];
  }

  private readonly statsAiCache = new Map<string, { data: any; timestamp: number }>();

  async getStatistics(userId: string) {
    const profile = await this.cultivationService.getProfile(userId);
    const userCamps = await this.getUserCampaigns(userId);

    const activeCamp = userCamps[0] || null;
    const hasActiveCamp = activeCamp != null;
    const activeCampaignTitle = activeCamp?.title || '[HỆ THỐNG] Tôi Luyện Thể Chất & Đột Phá Giới Hạn';
    const campaignTotalDays = activeCamp?.durationDays || 14;

    let campaignCurrentDay = hasActiveCamp ? 1 : 0;
    if (activeCamp?.createdAt) {
      try {
        const start = new Date(activeCamp.createdAt);
        const now = new Date();
        const diffDays = Math.floor((now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
        campaignCurrentDay = Math.min(Math.max(1, diffDays + 1), campaignTotalDays);
      } catch (_) {}
    }

    const campaignProgress = hasActiveCamp ? Math.min(1.0, campaignCurrentDay / campaignTotalDays) : 0.0;
    const stageIndex = Math.min(3, Math.floor(campaignProgress * 4));
    const stages = ['Khởi động', 'Nền tảng', 'Đột phá', 'Duy trì'];
    const stageName = stages[stageIndex];

    const activeQuests = activeCamp?.quests || [];
    const completedQuestsCount = activeQuests.filter((q) => q.isCompleted || q.isXpClaimed).length;
    const totalQuestsCount = activeQuests.length;
    const completionRate = totalQuestsCount > 0 ? Math.round((completedQuestsCount / totalQuestsCount) * 100) : 0;
    const currentWeek = Math.floor((campaignCurrentDay - 1) / 7) + 1;
    const totalWeeks = Math.max(1, Math.ceil(campaignTotalDays / 7));
    const completedQuestsTotal = completedQuestsCount;
    const totalPlannedQuests = campaignTotalDays * 3;

    // 1. Thu thập tất cả nhiệm vụ của người dùng từ Supabase và in-memory
    const client = this.supabaseService.getClient();
    let allUserQuests: any[] = [];
    if (client) {
      try {
        const { data: dbQuests } = await client
          .from('quests')
          .select('*')
          .eq('user_id', userId);
        if (dbQuests && dbQuests.length > 0) {
          allUserQuests = dbQuests;
        }
      } catch (err: any) {
        this.logger.debug(`Không thể query bảng quests: ${err.message}`);
      }
    }

    for (const camp of userCamps) {
      if (Array.isArray(camp.quests)) {
        for (const q of camp.quests) {
          if (!allUserQuests.some((existing) => existing.id === q.id)) {
            allUserQuests.push(q);
          }
        }
      }
    }

    const completedQuestsList = allUserQuests.filter(
      (q) => q.is_completed || q.isCompleted || q.is_xp_claimed || q.isXpClaimed,
    );

    // 2. Phân loại và tính điểm các thuộc tính căn cốt từ nhiệm vụ thực tế
    let physicalPoints = 0;
    let intellectPoints = 0;
    let focusPoints = 0;
    let socialPoints = 0;

    for (const q of completedQuestsList) {
      const icon = (q.icon_type || q.iconType || '').toLowerCase();
      const text = `${q.title || ''} ${q.subtitle || ''}`.toLowerCase();
      const diff = (q.difficulty || 'MEDIUM').toUpperCase();
      const weight = diff.includes('HARD')
        ? 2.0
        : diff.includes('BREAKTHROUGH')
          ? 2.5
          : diff.includes('EASY')
            ? 1.0
            : 1.5;

      const isFitness =
        icon === 'fitness' ||
        icon === 'walk' ||
        icon === 'water' ||
        /chống đẩy|hít đất|gập bụng|squat|chạy|bộ|cardio|tạ|gym|luyện thể|vận động|nước|uống|cơ bắp|thể dục|thể lực|kéo xà|nhảy dây|plank/i.test(
          text,
        );
      const isStudy =
        icon === 'study' ||
        /học|đọc|sách|nghiên cứu|code|lập trình|bài tập|tiếng anh|ngoại ngữ|kiến thức|tri thức|chuyên môn|khóa học|viết lách/i.test(
          text,
        );
      const isFocus =
        icon === 'meditation' ||
        /tập trung|thiền|pomodoro|định tâm|tĩnh tâm|kỷ luật|ngủ|giấc ngủ|suy ngẫm|nhật ký|tự vấn|sâu/i.test(
          text,
        );
      const isSocial =
        icon === 'medal' ||
        /giao tiếp|kết nối|chia sẻ|đội nhóm|gia đình|bạn bè|lắng nghe|tâm thái|giúp đỡ|gặp gỡ|trò chuyện/i.test(
          text,
        );

      let matched = false;
      if (isFitness) {
        physicalPoints += weight;
        matched = true;
      }
      if (isStudy) {
        intellectPoints += weight;
        matched = true;
      }
      if (isFocus) {
        focusPoints += weight;
        matched = true;
      }
      if (isSocial) {
        socialPoints += weight;
        matched = true;
      }

      if (!matched) {
        const lowerCamp = activeCampaignTitle.toLowerCase();
        if (/cơ|bụng|múi|gym|chạy|thể dục|cân|nặng|workout|mỡ|giảm|tăng cân/i.test(lowerCamp)) {
          physicalPoints += weight;
        } else if (/học|đọc|sách|code|lập trình|thi|tiếng anh|nghiên cứu/i.test(lowerCamp)) {
          intellectPoints += weight;
        } else {
          focusPoints += weight;
        }
      }
    }

    // 3. Tính chỉ số Năng Lực Đời Thực (Skill Tree) chuẩn xác dựa trên dữ liệu thật
    // Khởi điểm cơ bản của một Phàm Nhân là 10%
    const realmBonus =
      (profile.realmIndex || 0) * 5 + Math.min(5, Math.floor((profile.subRealm || 1) * 0.5));
    const totalExpVal = Number(profile.totalExp || profile.currentExp || 0);
    const expBonus = Math.min(15, Math.floor(totalExpVal / 250));
    const streakDays = Math.max(0, profile.streakDays || 0);

    const calculatedPhysical = Math.min(
      99,
      Math.max(
        10,
        Math.round(
          10 + realmBonus + expBonus + Math.floor(streakDays * 1.0) + Math.min(50, physicalPoints * 8),
        ),
      ),
    );

    const calculatedIntellect = Math.min(
      99,
      Math.max(
        10,
        Math.round(
          10 + realmBonus + expBonus + Math.floor(streakDays * 1.0) + Math.min(50, intellectPoints * 8),
        ),
      ),
    );

    const calculatedFocus = Math.min(
      99,
      Math.max(
        10,
        Math.round(
          10 + realmBonus + expBonus + streakDays * 3 + Math.min(50, focusPoints * 8),
        ),
      ),
    );

    const calculatedSocial = Math.min(
      99,
      Math.max(
        10,
        Math.round(
          10 +
            realmBonus +
            expBonus +
            Math.min(15, completedQuestsList.length * 2) +
            Math.min(50, socialPoints * 8),
        ),
      ),
    );

    const calculatedAttributes = {
      physical: calculatedPhysical,
      intellect: calculatedIntellect,
      focus: calculatedFocus,
      social: calculatedSocial,
    };

    // 4. Tính nhịp độ tu luyện 7 ngày (T2 -> CN) chuẩn xác từ lịch sử thực tế
    const now = new Date();
    const currentDayOfWeek = (now.getDay() + 6) % 7; // 0 = T2, ..., 6 = CN
    const calculatedWeeklyActivity = [0, 0, 0, 0, 0, 0, 0];

    const monday = new Date(now);
    monday.setDate(now.getDate() - currentDayOfWeek);
    monday.setHours(0, 0, 0, 0);

    for (const q of completedQuestsList) {
      const dateRaw = q.completed_at || q.completedAt || q.created_at || q.createdAt;
      if (dateRaw) {
        try {
          const d = new Date(dateRaw);
          if (d >= monday && d <= now) {
            const dayIdx = (d.getDay() + 6) % 7;
            calculatedWeeklyActivity[dayIdx] = Math.min(3, (calculatedWeeklyActivity[dayIdx] || 0) + 1);
          }
        } catch (_) {}
      }
    }

    calculatedWeeklyActivity[currentDayOfWeek] = Math.min(
      3,
      Math.max(calculatedWeeklyActivity[currentDayOfWeek], completedQuestsCount),
    );

    if (streakDays > 0) {
      const completedTodayFull = completedQuestsCount >= 3;
      const pastStreakDaysInWeek = completedTodayFull ? streakDays - 1 : streakDays;
      for (let offset = 1; offset <= pastStreakDaysInWeek; offset++) {
        const pastDayIdx = currentDayOfWeek - offset;
        if (pastDayIdx >= 0) {
          calculatedWeeklyActivity[pastDayIdx] = Math.max(calculatedWeeklyActivity[pastDayIdx], 3);
        }
      }
    }

    // Check AI cache (10 minutes)
    const cacheKey = `${userId}_${activeCampaignTitle}_${profile.streakDays}_${completedQuestsTotal}`;
    const cached = this.statsAiCache.get(cacheKey);
    let aiEvaluation: any = null;

    if (cached && Date.now() - cached.timestamp < 10 * 60 * 1000) {
      aiEvaluation = cached.data;
    }

    // Call Gemini AI if available and not cached
    if (!aiEvaluation && this.genAiClient) {
      try {
        const prompt = `Bạn là "Thiên Đạo AI" trong hệ thống tu chân hiện đại Tiên Lộ (Gamified Habit & Self-Improvement App).
Hệ thống đã tính toán căn cốt năng lực đời thực của Đạo hữu dựa trên hành vi tu luyện thực tế:
- Thể chất: ${calculatedAttributes.physical}%
- Trí thức: ${calculatedAttributes.intellect}%
- Định lực / Tập trung: ${calculatedAttributes.focus}%
- Giao tiếp / Tâm thái: ${calculatedAttributes.social}%
- Cảnh giới hiện tại: ${profile.realmName} Tầng ${profile.subRealm}
- Chuỗi ngày tu luyện: ${streakDays} ngày
- Linh lực EXP: ${profile.currentExp}/${profile.maxExp}
- Mục tiêu/Chiến dịch hiện tại: "${activeCampaignTitle}" (Ngày ${campaignCurrentDay}/${campaignTotalDays}, Chặng: ${stageName})
- Số nhiệm vụ hoàn thành hôm nay: ${completedQuestsCount}/${totalQuestsCount}
- Các nhiệm vụ tu luyện: ${activeQuests.map((q) => q.title).join('; ') || 'Rèn luyện thân thể, đọc sách, định tâm'}

Hãy trả về JSON theo đúng định dạng sau (chỉ JSON thuần túy, không có markdown formatting hay chú thích):
{
  "aiIntelligence": {
    "tag": "WEEKLY INTELLIGENCE • THIÊN ĐẠO AI",
    "bestTime": "<khung giờ tu luyện tốt nhất, ví dụ: '6–8h sáng' hoặc '20–22h tối'>",
    "title": "<1 câu tiêu đề đúc kết nhận xét từ AI sát với dữ liệu thực tế>",
    "advice": "<2-3 câu lời bình sâu sắc, uyên bác theo phong cách Tiên Hiệp kết hợp phát triển bản thân, chỉ ra điểm mạnh và điểm cần cải thiện>",
    "growthTrend": "+${Math.min(25, Math.max(3, streakDays * 3 + completedQuestsCount * 2))}% tuần này"
  }
}`;

        const candidateModels = [
          'gemini-3.5-flash-lite',
          'gemini-3.8-flash',
          'gemini-3.5-flash',
          'gemini-flash-latest',
        ];

        let response: any;
        for (const model of candidateModels) {
          try {
            response = await this.genAiClient.models.generateContent({
              model,
              contents: prompt,
              config: { responseMimeType: 'application/json' },
            });
            if (response?.text) break;
          } catch (modelErr: any) {
            this.logger.debug(`Model ${model} không khả dụng cho thống kê: ${modelErr.message}`);
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
    let fallbackAiIntelligence: any;
    if (completedQuestsList.length === 0 && streakDays === 0) {
      fallbackAiIntelligence = {
        tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
        bestTime: '6–8h sáng',
        title: 'Khởi đầu hành trình thăng cấp',
        advice:
          'Đạo hữu vừa bước lên Tiên Lộ. Hãy hoàn thành nhiệm vụ đầu tiên hôm nay để kích hoạt căn cốt và thu thập linh lực sơ khai!',
        growthTrend: '+0% khởi đầu',
      };
    } else if (
      calculatedPhysical >= calculatedIntellect &&
      calculatedPhysical >= calculatedFocus
    ) {
      fallbackAiIntelligence = {
        tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
        bestTime: '6–8h sáng',
        title: 'Căn cốt Thể chất tăng tiến vượt bậc',
        advice:
          'Thiên Đạo nhận thấy đạo hữu rất chăm chỉ luyện thể. Hãy bổ sung dinh dưỡng và nghỉ ngơi hợp lý để cơ bắp phục hồi tối ưu!',
        growthTrend: `+${Math.min(25, Math.max(3, streakDays * 3 + completedQuestsCount * 2))}% tuần này`,
      };
    } else if (
      calculatedIntellect >= calculatedPhysical &&
      calculatedIntellect >= calculatedFocus
    ) {
      fallbackAiIntelligence = {
        tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
        bestTime: '20–22h tối',
        title: 'Trí thức và Đạo tâm khai mở rõ nét',
        advice:
          'Trí thức và Định lực khai mở rất nhanh. Đừng quên vận động thể chất nhẹ nhàng để khí huyết lưu thông, tránh bế tắc kinh mạch!',
        growthTrend: `+${Math.min(25, Math.max(3, streakDays * 3 + completedQuestsCount * 2))}% tuần này`,
      };
    } else {
      fallbackAiIntelligence = {
        tag: 'WEEKLY INTELLIGENCE • THIÊN ĐẠO AI',
        bestTime: '5–7h sáng',
        title: 'Định lực tu vi đạt độ vững vàng',
        advice:
          'Chuỗi ngày kỷ luật đang tôi luyện thần thức vững như bàn thạch. Hãy tiếp tục duy trì nhịp độ tu luyện này!',
        growthTrend: `+${Math.min(25, Math.max(3, streakDays * 3 + completedQuestsCount * 2))}% tuần này`,
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
      attributes: calculatedAttributes,
      weeklyActivity: calculatedWeeklyActivity,
      aiIntelligence: aiEvaluation?.aiIntelligence || fallbackAiIntelligence,
    };
  }
}

