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

function cleanTopic(prompt: string): string {
  let cleaned = prompt
    .replace(/(tôi\s*(muốn|cần|đang|sẽ)|mục\s*tiêu|kế\s*hoạch|chiến\s*dịch|trong\s*\d+\s*(ngày|tuần|tháng)|trong\s*(nửa|một|hai|ba)\s*(tháng|tuần))/gi, '')
    .trim();
  if (cleaned.length < 3) cleaned = prompt.trim();
  return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
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

    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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

    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
  }

  // 3. Chạy bộ / Đi bộ / Cardio sức bền
  if (/chạy bộ|chạy|marathon|chay|cardio|nhảy dây|đi bộ|pace/i.test(lower)) {
    const km = pickRandom([3, 4, 5]);
    const easyPool: QuestTemplate[] = [
      {
        title: 'Khởi động kỹ khớp cổ chân, đầu gối và cơ đùi 10 phút',
        subtitle: 'Làm nóng nhịp tim để hạn chế tối đa nguy cơ chấn thương',
        difficulty: 'EASY',
        expReward: 80,
        stoneReward: 10,
        iconType: 'walk',
      },
      {
        title: 'Đi bộ nhanh 1.5km hoặc nhảy dây 250 cái nhịp nhàng',
        subtitle: 'Kích hoạt cơ gân kheo và điều hòa nhịp thở trước buổi chạy',
        difficulty: 'EASY',
        expReward: 90,
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
        title: 'Chạy bền 45 phút liên tục kết hợp ép dẻo giãn cơ sâu sau chạy',
        subtitle: 'Phục hồi cơ bắp toàn diện để chuẩn bị cho chuỗi ngày tiếp theo',
        difficulty: 'HARD',
        expReward: 440,
        stoneReward: 55,
        iconType: 'medal',
      },
    ];

    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
  }

  // 4. Thể hình / Gym / Tăng cơ / Calisthenics
  if (/gym|thể hình|tăng cơ|tạ|xà đơn|chống đẩy|hít đất|squat|cơ bụng|six pack|thể lực/i.test(lower)) {
    const pushCount = pickRandom([40, 50, 60]);
    const squatCount = pickRandom([60, 70, 80]);
    const easyPool: QuestTemplate[] = [
      {
        title: 'Khởi động làm nóng toàn thân & xoay khớp chuyên sâu 12 phút',
        subtitle: 'Kích hoạt hệ thần kinh trung ương và các sợi cơ mục tiêu',
        difficulty: 'EASY',
        expReward: 80,
        stoneReward: 10,
        iconType: 'fitness',
      },
      {
        title: 'Giãn cơ tĩnh 15 phút & nạp đủ 25g protein sau buổi tập',
        subtitle: 'Đảm bảo dưỡng chất cho cơ bắp phục hồi và gia tăng khối lượng',
        difficulty: 'EASY',
        expReward: 95,
        stoneReward: 12,
        iconType: 'fitness',
      },
    ];

    const medPool: QuestTemplate[] = [
      {
        title: `Chống đẩy ${pushCount} cái & Squat ${squatCount} cái chuẩn form`,
        subtitle: 'Chia làm 4 hiệp, ngực sát đất, kiểm soát chuyển động lúc hạ người',
        difficulty: 'MEDIUM',
        expReward: 230,
        stoneReward: 28,
        iconType: 'fitness',
      },
      {
        title: 'Tập luyện cơ trọng tâm: Plank 3 hiệp (mỗi hiệp 60s) & Gập bụng 50 cái',
        subtitle: 'Siết chặt cơ bụng suốt bài tập, không để võng thắt lưng',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
    ];

    const hardPool: QuestTemplate[] = [
      {
        title: 'Thử thách cực hạn: 100 cái Squat hoặc 20 cái kéo xà đơn',
        subtitle: 'Chia hiệp hợp lý, chạm ngưỡng thất bại để kích hoạt đồng hóa',
        difficulty: 'HARD',
        expReward: 410,
        stoneReward: 50,
        iconType: 'medal',
      },
      {
        title: 'Buổi tập tạ cường độ cao 50 phút bứt phá giới hạn tạ',
        subtitle: 'Tăng mức tạ lũy tiến (Progressive Overload) an toàn',
        difficulty: 'HARD',
        expReward: 430,
        stoneReward: 55,
        iconType: 'medal',
      },
    ];

    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
  }

  // 5. Tăng cân / Dinh dưỡng thể hình
  if (/tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân/i.test(lower)) {
    const easyPool: QuestTemplate[] = [
      {
        title: 'Bổ sung thêm 1 bữa phụ giàu protein và tinh bột tốt',
        subtitle: 'Sữa chua, chuối, hạt dinh dưỡng hoặc yến mạch giữa các bữa chính',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Tập kháng lực kích thích cơ bắp 40 phút (Squat, chống đẩy)',
        subtitle: 'Tập nặng để chuyển hóa calo dư thừa thành cơ nạc thay vì mỡ',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'fitness',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Đạt thặng dư 400-500 kcal trong ngày & ngủ đủ 8 tiếng',
        subtitle: 'Ngủ sâu phục hồi hormone tăng trưởng giúp đồng hóa tối đa',
        difficulty: 'HARD',
        expReward: 390,
        stoneReward: 45,
        iconType: 'medal',
      },
    ];
    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
  }

  // 6. Giảm cân / Giảm mỡ / Siết cơ
  if (/giảm cân|giảm mỡ|giam can|giam mo|siết cơ|thâm hụt calo|diet|ăn kiêng/i.test(lower)) {
    const easyPool: QuestTemplate[] = [
      {
        title: 'Cắt giảm 100% đường tinh luyện, nước ngọt có ga và bánh kẹo hôm nay',
        subtitle: 'Ổn định lượng đường huyết, chấm dứt cảm giác thèm ăn vặt',
        difficulty: 'EASY',
        expReward: 90,
        stoneReward: 12,
        iconType: 'fitness',
      },
    ];
    const medPool: QuestTemplate[] = [
      {
        title: 'Vận động đốt mỡ: Đạt 8.000 bước chân hoặc 30 phút cardio',
        subtitle: 'Gia tăng tiêu hao năng lượng ngoài tập luyện (NEAT)',
        difficulty: 'MEDIUM',
        expReward: 220,
        stoneReward: 26,
        iconType: 'walk',
      },
    ];
    const hardPool: QuestTemplate[] = [
      {
        title: 'Áp dụng nhịn ăn gián đoạn 16/8 và không ăn sau 20h tối',
        subtitle: 'Tạo cửa sổ thâm hụt calo giúp cơ thể dùng mỡ thừa làm năng lượng',
        difficulty: 'HARD',
        expReward: 400,
        stoneReward: 50,
        iconType: 'medal',
      },
    ];
    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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

    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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
    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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
    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickRandom(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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
    return [
      { ...pickRandom(easyPool), isDaily: true },
      { ...pickReward(medPool), isDaily: true },
      { ...pickRandom(hardPool), isDaily: true },
    ];
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

  return [
    { ...pickRandom(generalEasy), isDaily: true },
    { ...pickRandom(generalMed), isDaily: true },
    { ...pickRandom(generalHard), isDaily: true },
  ];
}

function pickReward(items: QuestTemplate[]): QuestTemplate {
  return pickRandom(items);
}
