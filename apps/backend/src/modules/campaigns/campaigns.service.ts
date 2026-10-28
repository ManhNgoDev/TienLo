import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { SupabaseService } from '../database/supabase.service.js';
import { CultivationService } from '../cultivation/cultivation.service.js';
import { QuestDifficulty, DIFFICULTY_REWARDS } from '../cultivation/cultivation.constants.js';
import { extractDurationDays, generateFallbackQuests, generateSingleExtraFallbackQuest } from './campaigns-fallback.helper.js';
import { computeCampaignStatistics } from './campaigns-statistics.helper.js';

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
    return extractDurationDays(goalPrompt, defaultDays);
  }

  async generateAiCampaign(
    userId: string,
    goalPrompt: string,
    durationDays: number = 14,
  ): Promise<GeneratedCampaign> {
    // 0. Giới hạn phiên tu luyện: Không cho phép tạo chiến dịch mới nếu đang có session dở dang
    const client = this.supabaseService.getClient();
    const userCamps = this.inMemoryCampaigns.get(userId) || [];
    let existingActiveCamp: any = null;

    if (client) {
      try {
        const { data: dbCamps } = await client
          .from('campaigns')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'ACTIVE')
          .order('created_at', { ascending: false })
          .limit(1);

        if (dbCamps && dbCamps.length > 0) {
          existingActiveCamp = dbCamps[0];
        }
      } catch (err: any) {
        this.logger.debug(`Kiểm tra campaign active thất bại: ${err.message}`);
      }
    }

    if (!existingActiveCamp && userCamps.length > 0) {
      existingActiveCamp = userCamps.find((c) => c.status === 'ACTIVE');
    }

    if (existingActiveCamp) {
      const durationTarget = Number(
        existingActiveCamp.duration_days ?? existingActiveCamp.durationDays ?? 14,
      );
      const createdAtRaw = existingActiveCamp.created_at ?? existingActiveCamp.createdAt;
      const createdDate = createdAtRaw ? new Date(createdAtRaw) : new Date();
      const now = new Date();
      const startDayUtc = Date.UTC(
        createdDate.getUTCFullYear(),
        createdDate.getUTCMonth(),
        createdDate.getUTCDate(),
      );
      const nowDayUtc = Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
      );
      const diffDays = Math.max(
        0,
        Math.floor((nowDayUtc - startDayUtc) / (1000 * 60 * 60 * 24)),
      );
      const currentDay = diffDays + 1;

      if (diffDays < durationTarget) {
        const remainingDays = Math.max(1, durationTarget - diffDays);
        throw new BadRequestException(
          `Đạo hữu đang trong chiến dịch hiện tại (Ngày ${currentDay}/${durationTarget} • còn ${remainingDays} ngày mục tiêu). Kể cả khi đã hoàn thành xong nhiệm vụ trong ngày, bắt buộc phải hết ${durationTarget} ngày mục tiêu của chiến dịch mới được tạo chiến dịch mới!`,
        );
      } else {
        // Đã hết toàn bộ số ngày mục tiêu của chiến dịch trước -> đóng chiến dịch cũ
        if (client) {
          try {
            await client
              .from('campaigns')
              .update({ status: 'COMPLETED' })
              .eq('id', existingActiveCamp.id);
          } catch (_) {}
        }
        existingActiveCamp.status = 'COMPLETED';
      }
    }

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
        const prompt = `Bạn là "HỆ THỐNG SOLO LEVELING" (Giao diện ban bố Mệnh Lệnh Nhiệm Vụ Hàng Ngày - Daily Quests tối thượng phong cách Thợ Săn Sung Jin-Woo kết hợp Tiên Lộ Tu Thân).
Người chơi (Người Thức Tỉnh) thiết lập mục tiêu rèn luyện đời thực: "${goalPrompt}".
Thời gian chiến dịch: ${calculatedDuration} ngày. MỖI NGÀY người chơi BẮT BUỘC nhận đúng 5 NHIỆM VỤ HÀNG NGÀY (Daily Quests).

QUY TẮC CỐT TỬ (BẮT BUỘC TUÂN THỦ NGHIÊM NGẶT 100%):
1. NHIỆM VỤ PHẢI LÀ MỆNH LỆNH HÀNH ĐỘNG CÓ CON SỐ ĐO ĐẾM RÕ RÀNG (ACTIONABLE REPS & QUANTIFIABLE METRICS):
   - Mọi nhiệm vụ PHẢI là một bài tập hoặc hành động cụ thể kèm con số đếm dứt khoát (Số lần, cái, phút, km, trang, dòng, bài) chuẩn phong cách Daily Quest của Solo Leveling ("100 cái hít đất, 100 cái gập bụng, 100 cái squat, chạy 10km").
   - Nếu mục tiêu liên quan THỂ DỤC / GẬP BỤNG / TẬP GYM / RÈN THÂN THỂ / GIẢM MỠ / TĂNG CÂN / SỨC KHỎE / WORKOUT:
     * BẮT BUỘC tạo các bài tập đếm số lần rõ ràng theo cú pháp: [Tên động tác] + [Số lượng cụ thể]:
       + "Gập bụng (Sit-ups) 50 lần" (chia 2-3 hiệp)
       + "Chống đẩy (Push-ups) 35 cái" (chuẩn form ngực sát đất)
       + "Squat (Gánh đùi) 50 lần" (đùi song song sàn)
       + "Plank siết cơ bụng 60 giây" (3 hiệp)
       + "Gập bụng đạp xe (Bicycle Crunches) 60 lần"
       + "Nhảy dây 300 cái" hoặc "Chạy bộ 3.0 km"
       + "Kéo xà đơn (Pull-ups) 15 cái"
   - Nếu mục tiêu liên quan HỌC TẬP / LẬP TRÌNH / NGOẠI NGỮ / ĐỌC SÁCH:
     * BẮT BUỘC có con số định lượng rõ ràng:
       + "Đọc chính xác 25 trang sách chuyên môn"
       + "Giải 2 bài tập thuật toán LeetCode hoặc viết 60 dòng code"
       + "Học thuộc và viết lại 20 từ vựng mới"
       + "Tập trung học sâu Pomodoro đúng 45 phút không xao nhãng"

2. TUYỆT ĐỐI CẤM NHIỆM VỤ DẠNG LỜI NHẮC NHỞ, KHUYÊN BẢO, MƠ HỒ:
   - ❌ CẤM TUYỆT ĐỐI: "Khởi động làm nóng", "Nhớ uống đủ 2L nước", "Không ăn đồ ngọt", "Ngủ sớm trước 23h", "Duy trì tinh thần lạc quan", "Giãn cơ phục hồi", "Chuẩn bị tư duy", "Ý thức nâng cao sức khỏe", "Ăn uống điều độ".
   - ✔️ BẮT BUỘC: Mọi nhiệm vụ PHẢI là CHỈ TIÊU HÀNH ĐỘNG RÕ RÀNG. Người chơi đếm đủ số lần / làm xong số phút / đọc xong số trang là tick hoàn thành.

3. PHÂN BỔ 5 CẤP ĐỘ NHIỆM VỤ MỖI NGÀY:
   - 2 Nhiệm vụ độ khó EASY (DỄ): Chỉ tiêu vừa sức khởi đầu (Ví dụ: Gập bụng 30 lần, Chống đẩy 20 cái, Squat 35 cái, Đọc 15 trang, Học 15 từ). Thưởng: 80-120 Linh Lực (EXP), 10-15 Nguyên Thạch.
   - 2 Nhiệm vụ độ khó MEDIUM (VỪA): Trọng tâm thực chiến (Ví dụ: Gập bụng 60 lần, Chống đẩy 40 cái, Squat 60 cái, Code 60 dòng, Học 40 phút). Thưởng: 150-250 Linh Lực (EXP), 20-30 Nguyên Thạch.
   - 1 Nhiệm vụ độ khó HARD (KHÓ): Cực hạn bứt phá (Ví dụ: 100 lần gập bụng, 100 cái squat, 60 cái chống đẩy, Chạy 3.5km, Code module hoàn chỉnh). Thưởng: 300-500 Linh Lực (EXP), 40-60 Nguyên Thạch.

QUY TẮC ĐỊNH DẠNG JSON:
- "campaignTitle": Tiêu đề chiến dịch đậm chất Solo Leveling (Ví dụ: "[HỆ THỐNG] Mệnh Lệnh Rèn Luyện: ${goalPrompt}").
- "title": Tên bài tập / hành động + số lượng rõ ràng (Ví dụ: "Gập bụng (Sit-ups) 50 lần", "Chống đẩy (Push-ups) 35 cái", "Squat 50 lần").
- "subtitle": Lời huấn thị nghiêm khắc từ Hệ Thống (Ví dụ: "Chia 3 hiệp, siết cơ chuẩn form. Không hoàn thành sẽ bị xử phạt!").
- "difficulty": "EASY", "MEDIUM", hoặc "HARD".
- "iconType": "fitness", "study", "walk", "meditation", "water", "medal".
- Trả về đúng 5 nhiệm vụ (2 EASY, 2 MEDIUM, 1 HARD).

Trả về DUY NHẤT một JSON hợp lệ không có giải thích thêm:
{
  "campaignTitle": "[HỆ THỐNG] Thăng Cấp Thợ Săn: ${goalPrompt}",
  "durationDays": ${calculatedDuration},
  "quests": [
    {
      "title": "Gập bụng (Sit-ups) 35 lần",
      "subtitle": "Chia 2 hiệp, siết chặt cơ bụng khởi đầu",
      "difficulty": "EASY",
      "expReward": 100,
      "stoneReward": 15,
      "iconType": "fitness",
      "isDaily": true
    },
    {
      "title": "Plank siết cơ bụng 45 giây",
      "subtitle": "Giữ thẳng sống lưng, thở đều đặn",
      "difficulty": "EASY",
      "expReward": 110,
      "stoneReward": 15,
      "iconType": "fitness",
      "isDaily": true
    },
    {
      "title": "Chống đẩy (Push-ups) 30 cái",
      "subtitle": "Ngực sát đất, siết cơ lõi chuẩn form",
      "difficulty": "MEDIUM",
      "expReward": 220,
      "stoneReward": 25,
      "iconType": "fitness",
      "isDaily": true
    },
    {
      "title": "Gập bụng đạp xe (Bicycle Crunches) 50 lần",
      "subtitle": "Khai phá toàn diện cơ liên sườn và bụng dưới",
      "difficulty": "MEDIUM",
      "expReward": 240,
      "stoneReward": 28,
      "iconType": "fitness",
      "isDaily": true
    },
    {
      "title": "Squat (Gánh đùi) 70 cái",
      "subtitle": "Đùi song song mặt đất, bứt phá giới hạn thể lực",
      "difficulty": "HARD",
      "expReward": 420,
      "stoneReward": 50,
      "iconType": "medal",
      "isDaily": true
    }
  ]
}`;

        const candidateModels = [
          'gemini-2.5-flash',
          'gemini-2.0-flash',
          'gemini-1.5-flash',
        ];

        let response: any;
        for (const model of candidateModels) {
          try {
            response = await this.genAiClient.models.generateContent({
              model,
              contents: prompt,
              config: {
                responseMimeType: 'application/json',
                temperature: 0.85,
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
          rawQuests = parsed.quests.slice(0, 5);
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

    // 3. Chuẩn hóa danh sách Quests (luôn đảm bảo 5 nhiệm vụ mỗi ngày)
    const quests: GeneratedQuest[] = rawQuests.slice(0, 5).map((q, idx) => {
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
    if (client) {
      try {
        await client.from('campaigns').insert({
          id: campaign.id,
          user_id: userId,
          title: campaign.title,
          goal_prompt: goalPrompt,
          duration_days: finalDuration,
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

    userCamps.unshift(campaign);
    this.inMemoryCampaigns.set(userId, userCamps);

    return campaign;
  }

  async getUserCampaigns(userId: string): Promise<GeneratedCampaign[]> {
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        const [campsRes, questsRes] = await Promise.all([
          client
            .from('campaigns')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false }),
          client
            .from('quests')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: true }),
        ]);

        const camps = campsRes.data;
        const allQuests = questsRes.data || [];

        if (camps && camps.length > 0) {
          return camps.map((c: any, campIdx: number) => {
            const campQuests = allQuests.filter(
              (q: any) =>
                q.campaign_id === c.id ||
                (!q.campaign_id && campIdx === 0),
            );
            return {
              id: c.id,
              userId: c.user_id,
              title: c.title,
              goalPrompt: c.goal_prompt,
              durationDays: c.duration_days,
              status: c.status,
              createdAt: c.created_at,
              quests: campQuests.map((q: any) => ({
                id: q.id,
                campaignId: q.campaign_id || c.id,
                title: q.title,
                subtitle: q.subtitle,
                difficulty: q.difficulty as QuestDifficulty,
                expReward: q.exp_reward,
                stoneReward: q.stone_reward,
                iconType: q.icon_type,
                isDaily: q.is_daily,
                isCompleted: Boolean(q.is_completed),
                isXpClaimed: Boolean(q.is_xp_claimed),
                completedAt: q.completed_at,
                createdAt: q.created_at,
              })),
            };
          });
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi truy vấn getUserCampaigns: ${err.message}`);
      }
    }

    return this.inMemoryCampaigns.get(userId) || [];
  }

  async completeQuest(
    userId: string,
    questId: string,
    body?: {
      allCompleted?: boolean;
      streakDays?: number;
      localDate?: string;
      questTitle?: string;
      exp?: number;
      spiritStones?: number;
    },
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

    const expAwarded = body?.exp || targetQuest?.expReward || 150;
    const stonesAwarded = body?.spiritStones || targetQuest?.stoneReward || 20;

    // Cộng Linh Lực & Linh Thạch qua CultivationService
    const expResult = await this.cultivationService.addExp(userId, expAwarded);
    await this.cultivationService.addSpiritStones(
      userId,
      stonesAwarded,
      `Thưởng hoàn thành nhiệm vụ: ${body?.questTitle || targetQuest?.title || questId}`,
    );

    // Cập nhật Supabase (nếu nhiệm vụ sinh ra ở ngày mới trên client chưa có trong bảng quests thì insert bổ sung)
    const client = this.supabaseService.getClient();
    if (client) {
      try {
        const { data: updatedRows } = await client
          .from('quests')
          .update({
            is_completed: true,
            is_xp_claimed: true,
            completed_at: new Date().toISOString(),
          })
          .eq('id', questId)
          .select('id');

        if (!updatedRows || updatedRows.length === 0) {
          let activeCampId: string | null = null;
          const { data: activeCamps } = await client
            .from('campaigns')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'ACTIVE')
            .order('created_at', { ascending: false })
            .limit(1);
          if (activeCamps && activeCamps.length > 0) {
            activeCampId = activeCamps[0].id;
          }
          await client.from('quests').upsert({
            id: questId,
            campaign_id: activeCampId,
            user_id: userId,
            title: body?.questTitle || targetQuest?.title || 'Nhiệm vụ tu luyện hàng ngày',
            subtitle: targetQuest?.subtitle || 'Hoàn thành nhiệm vụ tu luyện',
            difficulty: targetQuest?.difficulty || 'MEDIUM',
            exp_reward: expAwarded,
            stone_reward: stonesAwarded,
            icon_type: targetQuest?.iconType || 'fitness',
            is_daily: true,
            is_completed: true,
            is_xp_claimed: true,
            completed_at: new Date().toISOString(),
          });
        }
      } catch (_) {}
    }

    // Kiểm tra xem tất cả nhiệm vụ trong chiến dịch hôm nay đã hoàn thành chưa
    let allCompleted = body?.allCompleted === true;

    if (!allCompleted) {
      for (const c of userCamps) {
        if (c.quests.some((item) => item.id === questId)) {
          if (c.quests.length > 0 && c.quests.every((q) => q.isCompleted || q.isXpClaimed)) {
            allCompleted = true;
          }
          break;
        }
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
    let streakIncremented = false;

    if (allCompleted) {
      const streakRes = await this.cultivationService.incrementStreakIfEligible(
        userId,
        body?.localDate,
        body?.streakDays,
      );
      finalCultivationState = streakRes.profile;
      streakIncremented = streakRes.streakIncremented;
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

  async generateExtraQuest(
    userId: string,
    goalPrompt: string,
    existingTitles: string[] = [],
    campaignId?: string,
  ): Promise<GeneratedQuest> {
    let resolvedCampaignId = campaignId;
    const client = this.supabaseService.getClient();

    if (!resolvedCampaignId) {
      if (client) {
        try {
          const { data: dbCamps } = await client
            .from('campaigns')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'ACTIVE')
            .order('created_at', { ascending: false })
            .limit(1);
          if (dbCamps && dbCamps.length > 0) {
            resolvedCampaignId = dbCamps[0].id;
          }
        } catch (_) {}
      }
      if (!resolvedCampaignId) {
        const userCamps = this.inMemoryCampaigns.get(userId) || [];
        const active = userCamps.find((c) => c.status === 'ACTIVE');
        if (active) resolvedCampaignId = active.id;
      }
    }
    if (!resolvedCampaignId) {
      resolvedCampaignId = `camp-${Date.now()}`;
    }

    let rawQuest: {
      title: string;
      subtitle: string;
      difficulty: string;
      expReward?: number;
      stoneReward?: number;
      iconType?: string;
      isDaily?: boolean;
    } | null = null;

    if (this.genAiClient) {
      try {
        const prompt = `Bạn là "HỆ THỐNG SOLO LEVELING" (Giao diện ban bố Mệnh Lệnh Nhiệm Vụ Hàng Ngày tối thượng).
Người chơi (Người Thức Tỉnh) muốn LÀM THÊM / BỨT PHÁ GIỚI HẠN với mục tiêu: "${goalPrompt}".
Danh sách các nhiệm vụ hiện tại đã có (TUYỆT ĐỐI KHÔNG ĐƯỢC TRÙNG LẶP):
${existingTitles.length > 0 ? existingTitles.map((t) => `- ${t}`).join('\n') : '- Chưa có nhiệm vụ nào'}

QUY TẮC CỐT TỬ:
1. MỆNH LỆNH HÀNH ĐỘNG CÓ SỐ ĐO ĐẾM RÕ RÀNG (Actionable reps & quantifiable metrics):
   - BẮT BUỘC có số đếm dứt khoát: [Tên động tác/hành động] + [Số lượng cụ thể] (Ví dụ: "Gập bụng đạp xe 50 lần", "Nhảy dây 300 cái", "Hít xà đơn 15 cái", "Đọc 20 trang sách", "Giải 1 bài LeetCode").
2. TUYỆT ĐỐI CẤM LỜI NHẮC NHỞ, KHUYÊN BẢO MƠ HỒ ("uống nước", "nghỉ ngơi", "ngủ sớm").
3. ĐÂY LÀ NHIỆM VỤ LÀM THÊM ĐỘT PHÁ:
   - Độ khó nên là HARD hoặc MEDIUM.
   - Thưởng: 250-450 Linh Lực (EXP), 30-50 Nguyên Thạch.

Trả về DUY NHẤT một JSON hợp lệ:
{
  "title": "Gập bụng đạp xe (Bicycle Crunches) 50 lần",
  "subtitle": "Khai mở cực hạn cơ thể, siết chặt cơ liên sườn chuẩn form",
  "difficulty": "HARD",
  "expReward": 350,
  "stoneReward": 40,
  "iconType": "fitness",
  "isDaily": true
}`;

        const candidateModels = [
          'gemini-2.5-flash',
          'gemini-2.0-flash',
          'gemini-1.5-flash',
        ];

        let response: any;
        for (const model of candidateModels) {
          try {
            response = await this.genAiClient.models.generateContent({
              model,
              contents: prompt,
              config: {
                responseMimeType: 'application/json',
                temperature: 0.9,
              },
            });
            if (response?.text) break;
          } catch (modelErr: any) {
            this.logger.debug(`Model ${model} không khả dụng cho extra quest: ${modelErr.message}`);
          }
        }

        const text = response?.text?.trim() || '';
        const parsed = JSON.parse(text);
        if (parsed.title) {
          rawQuest = parsed;
        }
      } catch (err: any) {
        this.logger.warn(`Lỗi Gemini AI khi tạo extra quest: ${err.message}`);
      }
    }

    if (!rawQuest) {
      rawQuest = generateSingleExtraFallbackQuest(goalPrompt, existingTitles);
    }

    let diff = QuestDifficulty.HARD;
    if (rawQuest.difficulty === 'EASY') diff = QuestDifficulty.EASY;
    else if (rawQuest.difficulty === 'MEDIUM') diff = QuestDifficulty.MEDIUM;
    else if (rawQuest.difficulty === 'BREAKTHROUGH') diff = QuestDifficulty.BREAKTHROUGH;

    const rewardTier = DIFFICULTY_REWARDS[diff];
    const expReward = rawQuest.expReward || rewardTier.minExp;
    const stoneReward = rawQuest.stoneReward || rewardTier.minStones;

    const quest: GeneratedQuest = {
      id: `q-${Date.now()}-extra`,
      campaignId: resolvedCampaignId,
      title: rawQuest.title,
      subtitle: rawQuest.subtitle || 'Nhiệm vụ bứt phá làm thêm',
      difficulty: diff,
      expReward,
      stoneReward,
      iconType: rawQuest.iconType || 'medal',
      isDaily: true,
      isCompleted: false,
      isXpClaimed: false,
    };

    if (client) {
      try {
        await client.from('quests').insert({
          id: quest.id,
          campaign_id: quest.campaignId,
          user_id: userId,
          title: quest.title,
          subtitle: quest.subtitle,
          difficulty: quest.difficulty,
          exp_reward: quest.expReward,
          stone_reward: quest.stoneReward,
          icon_type: quest.iconType,
          is_daily: true,
          is_completed: false,
          is_xp_claimed: false,
        });
      } catch (err: any) {
        this.logger.warn(`Lỗi lưu quest bổ sung vào Supabase: ${err.message}`);
      }
    }

    const userCamps = this.inMemoryCampaigns.get(userId) || [];
    const activeCamp = userCamps.find((c) => c.id === resolvedCampaignId);
    if (activeCamp) {
      activeCamp.quests.push(quest);
    }

    return quest;
  }

  private generateFallbackQuests(prompt: string) {
    return generateFallbackQuests(prompt);
  }

  async getStatistics(userId: string) {
    const profile = await this.cultivationService.getProfile(userId);
    const userCamps = await this.getUserCampaigns(userId);

    const client = this.supabaseService.getClient();
    let dbQuests: any[] = [];
    if (client) {
      try {
        const { data } = await client
          .from('quests')
          .select('*')
          .eq('user_id', userId);
        if (data && data.length > 0) {
          dbQuests = data;
        }
      } catch (err: any) {
        this.logger.debug(`Không thể query bảng quests: ${err.message}`);
      }
    }

    return computeCampaignStatistics({
      userId,
      profile,
      userCamps,
      dbQuests,
      genAiClient: this.genAiClient,
      logger: this.logger,
    });
  }
}

