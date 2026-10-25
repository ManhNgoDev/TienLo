import { GoogleGenAI } from '@google/genai';
import { Logger } from '@nestjs/common';
import { UserCultivationState } from '../cultivation/cultivation.service.js';
import { GeneratedCampaign } from './campaigns.service.js';

export interface CampaignStatisticsResult {
  activeCampaignTitle: string;
  campaignCurrentDay: number;
  campaignTotalDays: number;
  completedQuests: number;
  totalPlannedQuests: number;
  completionRate: number;
  currentWeek: number;
  totalWeeks: number;
  stageIndex: number;
  stageName: string;
  metrics: {
    streakDays: number;
    currentExp: number;
    maxExp: number;
    spiritStones: number;
    realmName: string;
    subRealm: number;
  };
  attributes: {
    physical: number;
    intellect: number;
    focus: number;
    social: number;
  };
  weeklyActivity: number[];
  aiIntelligence: any;
}

const statsAiCache = new Map<string, { data: any; timestamp: number }>();

export async function computeCampaignStatistics({
  userId,
  profile,
  userCamps,
  dbQuests,
  genAiClient,
  logger,
}: {
  userId: string;
  profile: UserCultivationState;
  userCamps: GeneratedCampaign[];
  dbQuests: any[];
  genAiClient: GoogleGenAI | null;
  logger: Logger;
}): Promise<CampaignStatisticsResult> {
  const activeCamp = userCamps[0] || null;
  const hasActiveCamp = activeCamp != null;
  const activeCampaignTitle =
    activeCamp?.title || '[HỆ THỐNG] Tôi Luyện Thể Chất & Đột Phá Giới Hạn';
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

  const campaignProgress = hasActiveCamp
    ? Math.min(1.0, campaignCurrentDay / campaignTotalDays)
    : 0.0;
  const stageIndex = Math.min(3, Math.floor(campaignProgress * 4));
  const stages = ['Khởi động', 'Nền tảng', 'Đột phá', 'Duy trì'];
  const stageName = stages[stageIndex];

  const activeQuests = activeCamp?.quests || [];
  const completedQuestsCount = activeQuests.filter((q) => q.isCompleted || q.isXpClaimed).length;
  const totalQuestsCount = activeQuests.length;
  const completionRate =
    totalQuestsCount > 0 ? Math.round((completedQuestsCount / totalQuestsCount) * 100) : 0;
  const currentWeek = Math.floor((campaignCurrentDay - 1) / 7) + 1;
  const totalWeeks = Math.max(1, Math.ceil(campaignTotalDays / 7));
  const completedQuestsTotal = completedQuestsCount;
  const totalPlannedQuests = campaignTotalDays * 3;

  // 1. Tổng hợp tất cả nhiệm vụ của người dùng
  const allUserQuests: any[] = [...(dbQuests || [])];
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

  // 2. Tính điểm căn cốt từ nhiệm vụ
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

  // 3. Tính điểm radar thuộc tính
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

  // 4. Tính tuần hoạt động 7 ngày (Thứ 2 -> Chủ Nhật)
  const now = new Date();
  const currentDayOfWeek = (now.getDay() + 6) % 7;
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

  // 5. Kiểm tra AI Cache
  const cacheKey = `${userId}_${activeCampaignTitle}_${profile.streakDays}_${completedQuestsTotal}`;
  const cached = statsAiCache.get(cacheKey);
  let aiEvaluation: any = null;

  if (cached && Date.now() - cached.timestamp < 10 * 60 * 1000) {
    aiEvaluation = cached.data;
  }

  if (!aiEvaluation && genAiClient) {
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
          response = await genAiClient.models.generateContent({
            model,
            contents: prompt,
            config: { responseMimeType: 'application/json' },
          });
          if (response?.text) break;
        } catch (modelErr: any) {
          logger.debug(`Model ${model} không khả dụng cho thống kê: ${modelErr.message}`);
        }
      }

      const text = response?.text?.trim() || '';
      aiEvaluation = JSON.parse(text);
      statsAiCache.set(cacheKey, { data: aiEvaluation, timestamp: Date.now() });
    } catch (err: any) {
      logger.warn(`Lỗi khi AI phân tích thống kê: ${err.message}. Sử dụng bộ quy tắc nội bộ.`);
    }
  }

  // Fallback thông minh
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
