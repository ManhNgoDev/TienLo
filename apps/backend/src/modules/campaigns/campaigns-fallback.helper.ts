export function extractDurationDays(goalPrompt: string, defaultDays: number = 14): number {
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

interface QuestTemplate {
  title: string;
  subtitle: string;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  expReward: number;
  stoneReward: number;
  iconType: string;
}

function pickRandom<T>(items: T[]): T {
  return items[Math.floor(Math.random() * items.length)];
}

function buildQuestsFromPools(
  easyPool: QuestTemplate[],
  medPool: QuestTemplate[],
  hardPool: QuestTemplate[],
  targetCount: number = 5,
): Array<QuestTemplate & { isDaily: boolean }> {
  const result: QuestTemplate[] = [];
  const usedTitles = new Set<string>();

  const pickFrom = (pool: QuestTemplate[], maxCount: number) => {
    const shuffled = [...pool].sort(() => 0.5 - Math.random());
    for (const item of shuffled) {
      if (!usedTitles.has(item.title) && maxCount > 0) {
        usedTitles.add(item.title);
        result.push(item);
        maxCount--;
      }
    }
  };

  // Ưu tiên: 2 EASY, 2 MEDIUM, 1 HARD (Tổng = 5)
  pickFrom(easyPool, 2);
  pickFrom(medPool, 2);
  pickFrom(hardPool, 1);

  // Nếu bất kỳ pool nào thiếu để đạt 5, bù đắp từ các pool còn lại
  if (result.length < targetCount) {
    const combined = [...medPool, ...hardPool, ...easyPool].sort(() => 0.5 - Math.random());
    for (const item of combined) {
      if (!usedTitles.has(item.title) && result.length < targetCount) {
        usedTitles.add(item.title);
        result.push(item);
      }
    }
  }

  // Dự phòng an toàn tuyệt đối
  while (result.length < targetCount && (easyPool.length || medPool.length || hardPool.length)) {
    const all = [...easyPool, ...medPool, ...hardPool];
    result.push(pickRandom(all));
  }

  return result.slice(0, targetCount).map((q) => ({ ...q, isDaily: true }));
}

function cleanTopic(prompt: string): string {
  let cleaned = prompt
    .replace(/(tôi\s*(muốn|cần|đang|sẽ)|mục\s*tiêu|kế\s*hoạch|chiến\s*dịch|trong\s*\d+\s*(ngày|tuần|tháng)|trong\s*(nửa|một|hai|ba)\s*(tháng|tuần))/gi, '')
    .trim();
  if (cleaned.length < 3) cleaned = prompt.trim();
  return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
}

export function generateSingleExtraFallbackQuest(
  prompt: string,
  existingTitles: string[] = [],
): {
  title: string;
  subtitle: string;
  difficulty: string;
  expReward: number;
  stoneReward: number;
  iconType: string;
  isDaily: boolean;
} {
  const allGenerated = generateFallbackQuests(prompt);
  const existingSet = new Set(existingTitles);
  const candidates = allGenerated.filter((q) => !existingSet.has(q.title));
  if (candidates.length > 0) {
    return candidates[Math.floor(Math.random() * candidates.length)];
  }
  return allGenerated[Math.floor(Math.random() * allGenerated.length)];
}

export function generateFallbackQuests(prompt: string): Array<{
  title: string;
  subtitle: string;
  difficulty: string;
  expReward: number;
  stoneReward: number;
  iconType: string;
  isDaily: boolean;
}> {
  const lower = prompt.toLowerCase();
  const topic = cleanTopic(prompt);

  // 1. Lập trình / Công nghệ / Code
  if (/code|lập trình|dev|python|javascript|typescript|react|flutter|backend|frontend|java|c\+\+|bug|git|api|thuật toán|leetcode/i.test(lower)) {
    const mins = pickRandom([30, 40, 45, 50]);
    const lines = pickRandom([40, 60, 80, 100]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Đọc 1 bài viết kỹ thuật hoặc tài liệu về ${topic}`,
        subtitle: 'Ghi chú 3 khái niệm kiến trúc hoặc cú pháp quan trọng trước khi code',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'study',
      },
      {
        title: 'Review và refactor 20 dòng code sạch sẽ',
        subtitle: 'Tối ưu đặt tên biến, xóa code thừa, chuẩn Clean Code',
        difficulty: 'EASY',
        expReward: 100,
        stoneReward: 15,
        iconType: 'study',
      },
      {
        title: 'Khởi động tư duy: Đọc hiểu 1 mẫu thiết kế (Design Pattern)',
        subtitle: 'Phân tích cách áp dụng trực tiếp vào dự án hiện tại',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'study',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Tập trung code chuyên sâu ${mins} phút về ${topic}`,
        subtitle: 'Bật chế độ tập trung Pomodoro, tuyệt đối không lướt mạng xã hội',
        difficulty: 'MEDIUM',
        expReward: 210,
        stoneReward: 25,
        iconType: 'study',
      },
      {
        title: `Viết ít nhất ${lines} dòng code và tự kiểm thử tính năng`,
        subtitle: 'Thực thi logic mượt mà, hạn chế tối đa lỗi runtime',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'study',
      },
      {
        title: 'Giải quyết triệt để 1 bài tập thuật toán hoặc 2 issue kỹ thuật',
        subtitle: 'Phân tích độ phức tạp thuật toán O(n) và tối ưu logic xử lý',
        difficulty: 'MEDIUM',
        expReward: 240,
        stoneReward: 30,
        iconType: 'study',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: `Bứt phá: Hoàn thiện 1 module chức năng của ${topic}`,
        subtitle: 'Tối ưu hóa hiệu năng, xử lý ngoại lệ và commit Git bài bản',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Sprint lập trình 60 phút: Debug triệt để và viết tài liệu API',
        subtitle: 'Khắc phục hoàn toàn các lỗi tiềm ẩn, nâng cao độ bền bỉ của hệ thống',
        difficulty: 'HARD',
        expReward: 430,
        stoneReward: 55,
        iconType: 'medal',
      },
    ];

    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 2. Ngoại ngữ (Tiếng Anh, IELTS, TOEIC, Tiếng Nhật, Hàn, Trung...)
  if (/tiếng anh|english|ielts|toeic|tiếng nhật|tiếng hàn|tiếng trung|ngoại ngữ|ngữ pháp|phát âm|từ vựng/i.test(lower)) {
    const vocabCount = pickRandom([15, 20, 25, 30]);
    const listenMins = pickRandom([20, 25, 30, 35]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Học ${vocabCount} từ vựng mới bằng phương pháp lặp lại ngắt quãng`,
        subtitle: 'Ứng dụng flashcard hoặc đặt câu trực tiếp với từng từ',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'study',
      },
      {
        title: 'Luyện phát âm chuẩn IPA 15 phút với từ điển giọng bản xứ',
        subtitle: 'Tập trung khẩu hình miệng, trọng âm và nối âm tự nhiên',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'study',
      },
      {
        title: 'Luyện đọc to trôi chảy 1 đoạn văn ngoại ngữ 15 phút',
        subtitle: 'Chú trọng ngữ điệu và ngắt nghỉ tự nhiên theo câu',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'study',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Luyện nghe podcast / video ${listenMins} phút kết hợp nhại giọng (Shadowing)`,
        subtitle: 'Nghe không bật phụ đề lần đầu, sau đó nhại lại đúng ngữ điệu bản ngữ',
        difficulty: 'MEDIUM',
        expReward: 210,
        stoneReward: 25,
        iconType: 'study',
      },
      {
        title: 'Đọc hiểu sâu 1 bài báo chuyên ngành và tóm tắt lại bằng ngoại ngữ',
        subtitle: 'Ghi chú ít nhất 5 cụm Collocations cao cấp',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'study',
      },
      {
        title: 'Thực hành nói tiếng Anh theo chủ đề 25 phút bấm giờ',
        subtitle: 'Mở rộng vốn câu và phản xạ giao tiếp tự tin',
        difficulty: 'MEDIUM',
        expReward: 225,
        stoneReward: 27,
        iconType: 'study',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: 'Viết 1 bài luận 200 chữ hoặc luyện nói liên tục 15 phút ghi âm',
        subtitle: 'Tự nghe lại ghi âm hoặc kiểm tra ngữ pháp để sửa ngay các lỗi sai',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Giải trọn vẹn 1 đề thi thử trong điều kiện bấm giờ nghiêm ngặt',
        subtitle: 'Nghiệm thu đáp án chi tiết, phân tích cặn kẽ nguyên nhân câu sai',
        difficulty: 'HARD',
        expReward: 420,
        stoneReward: 55,
        iconType: 'medal',
      },
    ];

    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 3. Chạy bộ / Đi bộ / Cardio sức bền
  if (/chạy bộ|chạy|marathon|chay|cardio|nhảy dây|đi bộ|pace|bước chân/i.test(lower)) {
    const km = pickRandom([3, 4, 5]);
    const jumpRopes = pickRandom([250, 300, 350]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Nhảy dây ${jumpRopes} cái nhịp nhàng`,
        subtitle: 'Kích hoạt nhịp tim và điều hòa nhịp thở đều đặn',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'walk',
      },
      {
        title: 'Đi bộ nhanh 1.5km hoặc chạy nhẹ 10 phút',
        subtitle: 'Duy trì guồng chân đều đặn và hít thở sâu',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'walk',
      },
      {
        title: 'Squat bật nhảy (Jump Squats) 30 lần',
        subtitle: 'Tăng cường sức bật và sức bền cơ đùi',
        difficulty: 'EASY',
        expReward: 95,
        stoneReward: 12,
        iconType: 'walk',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Chạy bộ liên tục ${km}km với nhịp tim ổn định Zone 2`,
        subtitle: 'Duy trì sải chân đều đặn, thở sâu bằng mũi - miệng nhịp nhàng',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'walk',
      },
      {
        title: 'Gập bụng 50 lần kết hợp bật nhảy Burpees 20 cái',
        subtitle: 'Tổ hợp cardio đốt mỡ toàn thân cường độ cao',
        difficulty: 'MEDIUM',
        expReward: 240,
        stoneReward: 28,
        iconType: 'fitness',
      },
      {
        title: 'Chạy biến tốc (Fartlek): 6 hiệp chạy nhanh 1 phút xen kẽ đi bộ',
        subtitle: 'Bứt tốc nâng cao ngưỡng hấp thu oxy tối đa (VO2 Max)',
        difficulty: 'MEDIUM',
        expReward: 250,
        stoneReward: 30,
        iconType: 'walk',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: 'Chinh phục cự ly dài hoặc chạy dốc 6km bứt phá giới hạn',
        subtitle: 'Kiên trì hoàn thành cự ly mà không dừng lại, ý chí thợ săn quật cường',
        difficulty: 'HARD',
        expReward: 420,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Thử thách Cardio: Nhảy dây 500 cái & Chạy bền 35 phút',
        subtitle: 'Vượt ngưỡng mệt mỏi, nâng cấp thể lực toàn diện',
        difficulty: 'HARD',
        expReward: 440,
        stoneReward: 55,
        iconType: 'medal',
      },
    ];

    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 4. Thể dục / Thể hình / Gym / Gập bụng / Chống đẩy / Calisthenics
  if (/thể dục|tập thể dục|gym|thể hình|tăng cơ|tạ|xà đơn|chống đẩy|hít đất|squat|gập bụng|cơ bụng|six pack|thể lực|calisthenics|workout|luyện tập/i.test(lower)) {
    const pushCount = pickRandom([40, 50, 60]);
    const squatCount = pickRandom([50, 60, 70]);
    const situpEasy = pickRandom([30, 40, 45]);
    const situpMed = pickRandom([60, 70, 80]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Gập bụng (Sit-ups) ${situpEasy} lần`,
        subtitle: 'Chia 2-3 hiệp, siết chặt cơ bụng suốt bài tập',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
      {
        title: `Chống đẩy (Push-ups) ${pickRandom([20, 25, 30])} cái chuẩn form`,
        subtitle: 'Ngực sát đất, siết cơ lõi, không võng lưng',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'fitness',
      },
      {
        title: `Squat (Gánh đùi) ${pickRandom([35, 40, 45])} cái`,
        subtitle: 'Hạ mông đùi song song mặt sàn, siết cơ mông đùi',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
      {
        title: `Plank siết chặt cơ bụng ${pickRandom([45, 60])} giây`,
        subtitle: 'Giữ thân người thẳng tuyệt đối, kích hoạt toàn bộ cơ lõi',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'fitness',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Gập bụng (Sit-ups) ${situpMed} lần chia 3 hiệp`,
        subtitle: 'Siết chặt cơ bụng suốt bài tập, nâng người dứt khoát',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
      {
        title: `Chống đẩy ${pushCount} cái & Squat ${squatCount} cái chuẩn form`,
        subtitle: 'Chia làm 4 hiệp, ngực sát đất, kiểm soát chuyển động lúc hạ người',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'fitness',
      },
      {
        title: `Gập bụng đạp xe (Bicycle Crunches) ${pickRandom([50, 60, 70])} lần`,
        subtitle: 'Khuỷu tay chạm gối đối diện, siết liên sườn đốt mỡ eo',
        difficulty: 'MEDIUM',
        expReward: 225,
        stoneReward: 27,
        iconType: 'fitness',
      },
      {
        title: 'Tập cơ trọng tâm: Plank 3 hiệp (mỗi hiệp 60s) & 40 cái gập bụng',
        subtitle: 'Siết chặt cơ bụng suốt bài tập, không để võng thắt lưng',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: 'Thử thách cực hạn: 100 lần gập bụng (Sit-ups)',
        subtitle: 'Chia hiệp hợp lý, hoàn thành chuẩn form, ý chí sắt đá',
        difficulty: 'HARD',
        expReward: 410,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Thử thách cực hạn: 100 cái Squat & 50 cái chống đẩy',
        subtitle: 'Chia hiệp hợp lý, chạm ngưỡng thất bại để kích hoạt đồng hóa',
        difficulty: 'HARD',
        expReward: 420,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Chinh phục 15 cái kéo xà đơn (Pull-ups) hoặc 70 cái chống đẩy',
        subtitle: 'Kéo ngực chạm xà hoặc chống đẩy chuẩn biên độ',
        difficulty: 'HARD',
        expReward: 430,
        stoneReward: 55,
        iconType: 'medal',
      },
      {
        title: 'Gập bụng nâng chân (Leg Raises) 80 lần & Plank 120 giây',
        subtitle: 'Tôi luyện cơ bụng thép, đốt cháy mỡ thừa vùng bụng dưới',
        difficulty: 'HARD',
        expReward: 420,
        stoneReward: 52,
        iconType: 'medal',
      },
    ];

    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 5. Tăng cân / Dinh dưỡng thể hình
  if (/tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân/i.test(lower)) {
    const easyPool: QuestTemplate[] = [
      {
        title: 'Squat (Gánh đùi) 35 cái & Chống đẩy 20 cái kích thích cơ',
        subtitle: 'Kích hoạt các nhóm cơ lớn giúp cơ thể hấp thu dưỡng chất tối đa',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
      {
        title: 'Gập bụng 40 lần & Hít đất 25 cái tăng cường trao đổi chất',
        subtitle: 'Thúc đẩy tiêu hóa và kích thích sự thèm ăn lành mạnh',
        difficulty: 'EASY',
        expReward: 95,
        stoneReward: 12,
        iconType: 'fitness',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Tập kháng lực 40 phút: 50 cái Squat, 40 cái chống đẩy, 50 lần gập bụng',
        subtitle: 'Tập nặng để chuyển hóa calo thặng dư thành cơ nạc',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
      {
        title: 'Tổ hợp tăng cơ: 4 hiệp Squat (mỗi hiệp 20 cái) & 40 cái chống đẩy',
        subtitle: 'Kích hoạt tối đa áp lực cơ học lên các nhóm cơ lớn',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'fitness',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Thử thách thể lực: 8 hiệp Squat tăng tạ hoặc 80 cái Squat bodyweight',
        subtitle: 'Chạm ngưỡng mỏi cơ bắp, kích thích tối đa hormone phát triển',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'medal',
      },
    ];
    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 6. Giảm cân / Giảm mỡ / Siết cơ
  if (/giảm cân|giảm mỡ|giam can|giam mo|siết cơ|thâm hụt calo|diet|ăn kiêng/i.test(lower)) {
    const easyPool: QuestTemplate[] = [
      {
        title: 'Gập bụng (Sit-ups) 40 lần & Plank 60 giây siết eo',
        subtitle: 'Siết chặt cơ bụng, đốt cháy mỡ thừa vùng eo',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
      {
        title: 'Nhảy dây 300 cái đốt mỡ toàn thân',
        subtitle: 'Kích hoạt quá trình tiêu hao calo nhanh chóng',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'walk',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Vận động đốt mỡ: Đạt 8.000 bước chân hoặc 60 lần gập bụng đạp xe',
        subtitle: 'Gia tăng tiêu hao năng lượng, thắt chặt vòng 2',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
      {
        title: 'Chạy bộ 3.0 km hoặc 30 cái Burpees đốt mỡ',
        subtitle: 'Đẩy cao nhịp tim, duy trì trạng thái đốt mỡ sau tập luyện',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'walk',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Tổ hợp đốt mỡ cực hạn: 80 lần gập bụng, 60 cái squat, 30 cái burpees',
        subtitle: 'Tập liên hoàn đốt cháy calo cực đại, cơ bụng săn chắc',
        difficulty: 'HARD',
        expReward: 410,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Nhảy dây 600 cái & Plank 3 hiệp (mỗi hiệp 60 giây)',
        subtitle: 'Thử thách sức bền ý chí thợ săn, định hình cơ thể',
        difficulty: 'HARD',
        expReward: 420,
        stoneReward: 52,
        iconType: 'medal',
      },
    ];
    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 7. Đọc sách / Học tập / Nghiên cứu / Tri thức
  if (/đọc sách|doc sach|sách|đọc|ôn thi|học tập|nghiên cứu|kiến thức/i.test(lower)) {
    const pages = pickRandom([20, 25, 30, 35]);
    const studyMins = pickRandom([40, 45, 50, 60]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Đọc tập trung ${pages} trang sách không chạm vào điện thoại`,
        subtitle: 'Gạch chân và đánh dấu các luận điểm đắt giá nhất',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'study',
      },
      {
        title: 'Đúc kết 3 bài học tâm đắc nhất vào sổ tay tư duy',
        subtitle: 'Chuyển hóa tri thức trên trang sách thành hành động cụ thể',
        difficulty: 'EASY',
        expReward: 95,
        stoneReward: 12,
        iconType: 'study',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Phiên học sâu Deep Work ${studyMins} phút theo phương pháp Pomodoro`,
        subtitle: 'Ngắt kết nối mọi ứng dụng chat và thông báo gây xao nhãng',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'study',
      },
      {
        title: 'Vẽ sơ đồ tư duy (Mindmap) hệ thống hóa toàn bộ chương sách vừa đọc',
        subtitle: 'Liên kết các khái niệm mới với trải nghiệm thực tế đời sống',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'study',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: 'Áp dụng kỹ thuật Feynman: Tự giải thích lại chủ đề một cách đơn giản',
        subtitle: 'Nếu chưa thể giải thích dễ hiểu, hãy đọc lại phần còn mơ hồ',
        difficulty: 'HARD',
        expReward: 390,
        stoneReward: 48,
        iconType: 'medal',
      },
      {
        title: 'Viết bài tổng quan phản biện hoặc phân tích chuyên sâu 400 chữ',
        subtitle: 'Xây dựng góc nhìn độc lập, tôi luyện tư duy phản biện sắc bén',
        difficulty: 'HARD',
        expReward: 410,
        stoneReward: 50,
        iconType: 'medal',
      },
    ];

    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 8. Nghệ thuật / Âm nhạc / Đàn / Vẽ
  if (/đàn|guitar|piano|nhạc|hát|vocal|vẽ|hội họa|sketch|thiết kế|art/i.test(lower)) {
    const practiceMins = pickRandom([30, 40, 45]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Luyện ngón tay, gam âm giai hoặc phác thảo cơ bản 15 phút (${topic})`,
        subtitle: 'Xây dựng độ nhạy cảm và sự dẻo dai của đôi tay',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'study',
      },
      {
        title: `Luyện tập kỹ thuật cơ bản 20 phút (${topic})`,
        subtitle: 'Chỉnh sửa tư thế chuẩn và chuyển động tay dứt khoát',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'study',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: `Thực hành liên tục ${practiceMins} phút tác phẩm đang theo đuổi`,
        subtitle: 'Tập chậm từng đoạn khó, dùng máy đập nhịp (metronome) nếu cần',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'study',
      },
      {
        title: 'Luyện tập phân đoạn khó nhất của tác phẩm 30 phút tập trung',
        subtitle: 'Lặp lại tối thiểu 10 lần chuẩn xác không lỗi nhịp',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'study',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Thu âm hoặc hoàn thiện trọn vẹn 1 tác phẩm không ngắt quãng',
        subtitle: 'Nghiệm thu chất lượng tác phẩm, đánh giá sự tiến bộ rõ rệt',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'medal',
      },
    ];
    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 9. Tài chính / Tiết kiệm / Đầu tư
  if (/tiết kiệm|tài chính|đầu tư|tiền|chi tiêu|chứng khoán|ngân sách/i.test(lower)) {
    const easyPool: QuestTemplate[] = [
      {
        title: 'Ghi chép chính xác 100% tất cả các khoản chi tiêu trong ngày',
        subtitle: 'Phân loại chi tiêu thành Cần thiết (Needs) và Mong muốn (Wants)',
        difficulty: 'EASY',
        expReward: 80,
        stoneReward: 10,
        iconType: 'study',
      },
      {
        title: 'Kiểm tra số dư tài khoản và cập nhật bảng ngân sách cá nhân',
        subtitle: 'Nắm vững tình hình tài chính thực tế trước khi ra quyết định',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'study',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Đọc 1 báo cáo tài chính hoặc phân tích kinh tế chuyên sâu 30 phút',
        subtitle: 'Nâng cao tư duy quản trị dòng tiền và tích lũy tài sản dài hạn',
        difficulty: 'MEDIUM',
        expReward: 210,
        stoneReward: 25,
        iconType: 'study',
      },
      {
        title: 'Tối ưu hóa 1 chi phí định kỳ và tìm kiếm giải pháp gia tăng thu nhập',
        subtitle: 'Cắt giảm các gói dịch vụ thừa, tập trung vào giá trị sinh lời',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'study',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Cắt giảm triệt để 1 khoản chi phí thừa & chuyển ngay vào quỹ tiết kiệm',
        subtitle: 'Kỷ luật tài chính sắt đá tạo nên sự tự do đích thực',
        difficulty: 'HARD',
        expReward: 390,
        stoneReward: 48,
        iconType: 'medal',
      },
    ];
    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 10. Thiền định / Tâm thức / Giấc ngủ
  if (/thiền|tĩnh tâm|ngủ sớm|dậy sớm|mindfulness|tâm thức|thư giãn/i.test(lower)) {
    const medMins = pickRandom([10, 15, 20]);
    const easyPool: QuestTemplate[] = [
      {
        title: `Ngồi thiền thở sâu tĩnh tâm ${medMins} phút vào đầu ngày`,
        subtitle: 'Quan sát hơi thở tự nhiên, thanh lọc tâm trí khỏi âu lo',
        difficulty: 'EASY',
        expReward: 85,
        stoneReward: 10,
        iconType: 'meditation',
      },
      {
        title: 'Tập hít thở 4-7-8 đúng 10 chu kỳ đưa cơ thể vào trạng thái thư giãn',
        subtitle: 'Cân bằng hệ thần kinh đối giao cảm, giải tỏa stress tức thì',
        difficulty: 'EASY',
        expReward: 80,
        stoneReward: 10,
        iconType: 'meditation',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Dọn sạch góc làm việc & ngắt màn hình xanh 45 phút trước khi ngủ',
        subtitle: 'Tạo không gian tĩnh lặng, đưa não bộ vào trạng thái nghỉ ngơi',
        difficulty: 'MEDIUM',
        expReward: 200,
        stoneReward: 24,
        iconType: 'meditation',
      },
      {
        title: 'Thiền hành hoặc đi dạo tĩnh lặng 25 phút không dùng điện thoại',
        subtitle: 'Cảm nhận từng bước chân và hòa mình vào khoảnh khắc hiện tại',
        difficulty: 'MEDIUM',
        expReward: 210,
        stoneReward: 25,
        iconType: 'meditation',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Lên giường trước 22h30 và thức giấc đón nắng mai đúng giờ báo thức',
        subtitle: 'Thiết lập nhịp sinh học hoàn hảo, duy trì tinh thần minh mẫn',
        difficulty: 'HARD',
        expReward: 380,
        stoneReward: 46,
        iconType: 'medal',
      },
    ];
    return buildQuestsFromPools(easyPool, medPool, hardPool, 5);
  }

  // 11. Mặc định Thông Minh Đa Lĩnh Vực (Tự Động Bóc Tách Chủ Đề Của Người Dùng)
  // Tuyệt đối không ép buộc uống nước hay chống đẩy nếu mục tiêu là việc khác!
  const studyMins = pickRandom([30, 45, 50]);
  const actionMins = pickRandom([40, 50, 60]);

  const generalEasy: QuestTemplate[] = [
    {
      title: `Nghiên cứu tài liệu & lập danh mục hành động cho: ${topic}`,
      subtitle: 'Chuẩn bị đầy đủ công cụ và môi trường trước khi thực hiện',
      difficulty: 'EASY',
      expReward: 90,
      stoneReward: 12,
      iconType: 'study',
    },
    {
      title: `Khởi động 15 phút: Thực hiện bước vi mô đầu tiên của ${topic}`,
      subtitle: 'Bắt đầu nhẹ nhàng để kích hoạt đà hành động tích cực',
      difficulty: 'EASY',
      expReward: 85,
      stoneReward: 10,
      iconType: 'study',
    },
  ];

  const generalMed: QuestTemplate[] = [
    {
      title: `Tập trung sâu ${studyMins} phút thực hiện nhiệm vụ trọng tâm: ${topic}`,
      subtitle: 'Loại bỏ hoàn toàn thông báo gây phân tâm, duy trì trạng thái dòng chảy',
      difficulty: 'MEDIUM',
      expReward: 220,
      stoneReward: 26,
      iconType: 'study',
    },
    {
      title: `Thực hành nghiêm túc ${actionMins} phút nâng cao kỹ năng: ${topic}`,
      subtitle: 'Ghi chép các điểm cần cải thiện sau mỗi phiên rèn luyện',
      difficulty: 'MEDIUM',
      expReward: 230,
      stoneReward: 28,
      iconType: 'study',
    },
  ];

  const generalHard: QuestTemplate[] = [
    {
      title: `Bứt phá giới hạn: Hoàn tất 1 cột mốc quan trọng của ${topic}`,
      subtitle: 'Đánh giá kết quả bằng số liệu cụ thể, không chấp nhận sự trì hoãn',
      difficulty: 'HARD',
      expReward: 410,
      stoneReward: 50,
      iconType: 'medal',
    },
    {
      title: `Thử thách cực hạn: Tổng kết ngày và tối ưu hóa quy trình rèn luyện ${topic}`,
      subtitle: 'Tự kiểm điểm nghiêm khắc theo tinh thần Thợ Săn Thăng Cấp',
      difficulty: 'HARD',
      expReward: 430,
      stoneReward: 52,
      iconType: 'medal',
    },
  ];

  return buildQuestsFromPools(generalEasy, generalMed, generalHard, 5);
}

function pickReward(items: QuestTemplate[]): QuestTemplate {
  return pickRandom(items);
}
