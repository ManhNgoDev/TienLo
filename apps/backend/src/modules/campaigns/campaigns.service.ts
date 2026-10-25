import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { SupabaseService } from '../database/supabase.service.js';
import { CultivationService } from '../cultivation/cultivation.service.js';
import { QuestDifficulty, DIFFICULTY_REWARDS } from '../cultivation/cultivation.constants.js';
import { extractDurationDays, generateFallbackQuests } from './campaigns-fallback.helper.js';
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
          .select('*, quests(*)')
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
      const questsList = existingActiveCamp.quests || [];
      const hasUnfinished = questsList.some(
        (q: any) => !q.is_completed && !q.isCompleted,
      );

      if (hasUnfinished) {
        throw new BadRequestException(
          'Đạo hữu hiện đang có phiên tu luyện dở dang chưa hoàn tất! Cần hoàn thành toàn bộ nhiệm vụ hiện tại trước khi khai mở phiên tu luyện mới.',
        );
      } else {
        // Toàn bộ nhiệm vụ của session trước đã hoàn thành -> đóng session cũ
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
        const prompt = `Bạn là "HỆ THỐNG SOLO LEVELING" (Giao diện ban bố Nhiệm Vụ Hàng Ngày - Daily Quests chuẩn phong cách Thợ Săn Thăng Cấp Một Mình kết hợp Tiên Lộ Tu Thân).
Người chơi (Người Thức Tỉnh) thiết lập mục tiêu rèn luyện đời thực: "${goalPrompt}".
Thời gian chiến dịch được xác định là ${calculatedDuration} ngày. MỖI NGÀY người chơi BẮT BUỘC có đúng 3 NHIỆM VỤ HÀNG NGÀY (Daily Quests).

QUY TẮC CỐT LÕI (BẮT BUỘC TUÂN THỦ NGHIÊM NGẶT):
1. TUYỆT ĐỐI BÁM SÁT LĨNH VỰC CỦA MỤC TIÊU:
   - Nếu người chơi yêu cầu về LẬP TRÌNH / CNTT: Các nhiệm vụ PHẢI là viết code, debug, giải thuật toán, đọc tài liệu framework, refactor code, commit Git.
   - Nếu người chơi yêu cầu về NGOẠI NGỮ (Tiếng Anh, IELTS, Tiếng Nhật, v.v.): Các nhiệm vụ PHẢI là học từ vựng SRS, nghe podcast, shadowing, viết bài luận, làm đề thi.
   - Nếu người chơi yêu cầu về ĐỌC SÁCH / HỌC TẬP: Các nhiệm vụ PHẢI là đọc số trang sách cụ thể, ghi chép sơ đồ tư duy, giải bài tập, học sâu Pomodoro.
   - Nếu người chơi yêu cầu về NGHỆ THUẬT / ÂM NHẠC: Các nhiệm vụ PHẢI là luyện ngón đàn, ký họa, hoàn thiện tác phẩm, xướng âm.
   - NẾU VÀ CHỈ NẾU mục tiêu là THỂ THAO / TẬP GYM / CHẠY BỘ / GIẢM CÂN: Mới ban bố nhiệm vụ thể chất (chống đẩy, chạy bộ, squat, plank).
   - [ĐẶC BIỆT CẤM ĐOÁN]: TUYỆT ĐỐI KHÔNG TỰ TIỆN ĐƯA CÁC NHIỆM VỤ KHÔNG LIÊN QUAN NHƯ "UỐNG ĐỦ 2L NƯỚC", "CHỐNG ĐẨY", "GẬP BỤNG", "NGỦ ĐỦ GIẤC" VÀO CÁC MỤC TIÊU HỌC TẬP, CODE, NGOẠI NGỮ, TÀI CHÍNH HAY NGHỆ THUẬT!

2. TÍNH NGẪU NHIÊN VÀ ĐA DẠNG HÓA CAO (VARIETY & RANDOMIZATION):
   - Không được rập khuôn hay lặp lại các công thức cứng nhắc.
   - Linh hoạt thay đổi số lượng, thời gian (ví dụ: 25, 35, 45, 50 phút; 15, 25, 40 trang sách; 40, 70, 100 dòng code; 15, 20 từ vựng...).
   - Mang đến cảm giác mới mẻ, sống động và kích thích tính chinh phục của một Thợ Săn thực thụ.

3. ĐỊNH LƯỢNG RÕ RÀNG VÀ PHÂN BỔ 3 CẤP ĐỘ NHIỆM VỤ MỖI NGÀY:
   - Nhiệm vụ 1: Độ khó EASY (DỄ) - Hành động vi mô khởi động / tích lũy nền tảng phù hợp với lĩnh vực. Thưởng: 80-120 Linh Lực (EXP), 10-15 Nguyên Thạch.
   - Nhiệm vụ 2: Độ khó MEDIUM (VỪA) - Nhiệm vụ thực chiến trọng tâm của ngày (học sâu, code thực tế, luyện tập chính). Thưởng: 150-250 Linh Lực (EXP), 20-30 Nguyên Thạch.
   - Nhiệm vụ 3: Độ khó HARD (KHÓ) - Thử thách cực hạn bứt phá vùng an toàn / sản phẩm hoàn chỉnh / sprint chuyên sâu. Thưởng: 300-500 Linh Lực (EXP), 40-60 Nguyên Thạch.

QUY TẮC ĐỊNH DẠNG:
- "campaignTitle": Tiêu đề chiến dịch đậm chất Hệ Thống Solo Leveling (ví dụ: "[HỆ THỐNG] Khởi Động: Thăng Cấp Lập Trình Viên", "[HỆ THỐNG] Chinh Phục Cảnh Giới: Ngoại Ngữ Thượng Thừa", v.v.).
- "title": Bắt buộc chứa HÀNH ĐỘNG CỤ THỂ + CON SỐ ĐỊNH LƯỢNG (Ví dụ: "Học sâu Pomodoro 45 phút", "Viết 60 dòng code chuẩn Clean Code", "Học 20 từ vựng IELTS").
- "subtitle": Lời huấn thị nghiêm khắc, hướng dẫn kỹ thuật phong cách Hệ Thống Solo Leveling (Ví dụ: "Tập trung tuyệt đối, ngắt kết nối mạng xã hội. Không hoàn thành sẽ bị xử phạt!").
- "difficulty": CHỈ được là một trong 3 giá trị: "EASY", "MEDIUM", "HARD".
- "iconType": Chọn một trong: "study", "fitness", "walk", "meditation", "water", "medal".
- Trả về đúng 3 nhiệm vụ.

Trả về DUY NHẤT một JSON hợp lệ không có giải thích thêm, đúng cấu trúc sau:
{
  "campaignTitle": "[HỆ THỐNG] Thăng Cấp Thợ Săn: ${goalPrompt}",
  "durationDays": ${calculatedDuration},
  "quests": [
    {
      "title": "Tiêu đề hành động định lượng",
      "subtitle": "Lời huấn thị nghiêm khắc từ Hệ Thống",
      "difficulty": "EASY",
      "expReward": 100,
      "stoneReward": 15,
      "iconType": "study",
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

