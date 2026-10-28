import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/quest_item.dart';

class GoalAnalyzerService {
  static final _random = Random();

  static T _pick<T>(List<T> list) => list[_random.nextInt(list.length)];

  static int extractDurationDays(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('nửa tháng') || lower.contains('nua thang')) return 15;
    if (lower.contains('một tháng') || lower.contains('mot thang')) return 30;
    if (lower.contains('hai tháng') || lower.contains('hai thang')) return 60;
    if (lower.contains('ba tháng') || lower.contains('ba thang')) return 90;
    if (lower.contains('một tuần') || lower.contains('mot tuan')) return 7;
    if (lower.contains('hai tuần') || lower.contains('hai tuan')) return 14;
    if (lower.contains('ba tuần') || lower.contains('ba tuan')) return 21;
    if (lower.contains('bốn tuần') || lower.contains('bon tuan')) return 28;

    final weekMatch = RegExp(r'(\d+)\s*(tuần|tuan)').firstMatch(lower);
    if (weekMatch != null) {
      return int.parse(weekMatch.group(1)!) * 7;
    }
    final monthMatch = RegExp(r'(\d+)\s*(tháng|thang)').firstMatch(lower);
    if (monthMatch != null) {
      return int.parse(monthMatch.group(1)!) * 30;
    }
    final dayMatch = RegExp(r'(\d+)\s*(ngày|ngay|ng)').firstMatch(lower);
    if (dayMatch != null) {
      return int.parse(dayMatch.group(1)!);
    }
    return 14;
  }

  static QuestItem mapToQuestItem(dynamic q) {
    IconData icon = Icons.fitness_center_rounded;
    Color iconColor = const Color(0xFFF2C465);
    final iconType = q['iconType']?.toString().toLowerCase();
    if (iconType == 'water') {
      icon = Icons.water_drop_outlined;
      iconColor = const Color(0xFF38BDF8);
    } else if (iconType == 'walk') {
      icon = Icons.directions_walk_rounded;
      iconColor = const Color(0xFF34D399);
    } else if (iconType == 'meditation') {
      icon = Icons.self_improvement_rounded;
      iconColor = const Color(0xFFA78BFA);
    } else if (iconType == 'study') {
      icon = Icons.menu_book_rounded;
      iconColor = const Color(0xFF60A5FA);
    } else if (iconType == 'medal') {
      icon = Icons.military_tech_rounded;
      iconColor = const Color(0xFFFBBF24);
    }

    final diff = q['difficulty']?.toString().toUpperCase() ?? 'MEDIUM';
    final xp = (q['expReward'] as num?)?.toInt() ?? (q['xp'] as num?)?.toInt() ?? 150;
    final stones = (q['stoneReward'] as num?)?.toInt() ?? (q['spiritStones'] as num?)?.toInt() ?? 20;

    String subtitle = q['subtitle']?.toString() ?? 'Rèn luyện hàng ngày';
    subtitle = subtitle
        .replaceAll('Chiến dịch tu tiên mới · Hàng ngày', '')
        .replaceAll('Chiến dịch tu tiên mới', '')
        .replaceAll(RegExp(r'^(Luyện Thể|Trúc Cơ|Ngưng Đan|Thiên Kiếp|Đột Phá|Dễ|Vừa|Khó)\s*·\s*', caseSensitive: false), '')
        .trim();
    if (subtitle.isEmpty) {
      subtitle = 'Mục tiêu rèn luyện hàng ngày';
    }

    return QuestItem(
      id: q['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: q['title']?.toString() ?? 'Nhiệm vụ tu tiên',
      subtitle: subtitle,
      xp: xp,
      spiritStones: stones,
      difficulty: diff,
      icon: icon,
      iconColor: iconColor,
      isCompleted: q['isCompleted'] == true,
      isXpClaimed: q['isXpClaimed'] == true,
    );
  }

  static String _cleanTopic(String prompt) {
    String cleaned = prompt
        .replaceAll(RegExp(r'(tôi\s*(muốn|cần|đang|sẽ)|mục\s*tiêu|kế\s*hoạch|chiến\s*dịch|trong\s*\d+\s*(ngày|tuần|tháng)|trong\s*(nửa|một|hai|ba)\s*(tháng|tuần))', caseSensitive: false), '')
        .trim();
    if (cleaned.length < 3) cleaned = prompt.trim();
    if (cleaned.isEmpty) return 'Mục tiêu rèn luyện';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static List<QuestItem> _buildQuestsFromPools({
    required int now,
    required List<QuestItem> easyPool,
    required List<QuestItem> medPool,
    required List<QuestItem> hardPool,
    int targetCount = 5,
  }) {
    final result = <QuestItem>[];
    final usedTitles = <String>{};

    void pickFrom(List<QuestItem> pool, int maxCount) {
      final shuffled = List<QuestItem>.from(pool)..shuffle(_random);
      for (final item in shuffled) {
        if (!usedTitles.contains(item.title) && maxCount > 0) {
          usedTitles.add(item.title);
          result.add(item);
          maxCount--;
        }
      }
    }

    pickFrom(easyPool, 2);
    pickFrom(medPool, 2);
    pickFrom(hardPool, 1);

    if (result.length < targetCount) {
      final combined = [...medPool, ...hardPool, ...easyPool]..shuffle(_random);
      for (final item in combined) {
        if (!usedTitles.contains(item.title) && result.length < targetCount) {
          usedTitles.add(item.title);
          result.add(item);
        }
      }
    }

    while (result.length < targetCount && (easyPool.isNotEmpty || medPool.isNotEmpty || hardPool.isNotEmpty)) {
      final all = [...easyPool, ...medPool, ...hardPool];
      result.add(_pick(all));
    }

    return result.take(targetCount).toList().asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final q = entry.value;
      return QuestItem(
        id: 'q-$now-$idx',
        title: q.title,
        subtitle: q.subtitle,
        xp: q.xp,
        spiritStones: q.spiritStones,
        difficulty: q.difficulty,
        icon: q.icon,
        iconColor: q.iconColor,
      );
    }).toList();
  }

  static QuestItem generateSingleExtraQuest(String goalText, {List<String>? existingTitles}) {
    final quests = analyzeGoalAndCreateQuests(goalText);
    final existingSet = existingTitles != null ? Set<String>.from(existingTitles) : <String>{};
    final candidates = quests.where((q) => !existingSet.contains(q.title)).toList();
    final picked = candidates.isNotEmpty ? _pick(candidates) : _pick(quests);

    final now = DateTime.now().millisecondsSinceEpoch;
    return QuestItem(
      id: 'q-$now-extra',
      title: picked.title,
      subtitle: 'Nhiệm vụ bứt phá làm thêm · Rèn luyện vượt giới hạn',
      xp: (picked.xp * 1.15).toInt().clamp(250, 480),
      spiritStones: (picked.spiritStones * 1.2).toInt().clamp(25, 60),
      difficulty: 'HARD',
      icon: picked.icon,
      iconColor: picked.iconColor,
    );
  }

  static List<QuestItem> analyzeGoalAndCreateQuests(String goalText) {
    final lower = goalText.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch;
    final topic = _cleanTopic(goalText);

    // 1. Lập trình / Công nghệ / Code
    if (RegExp(r'code|lập trình|dev|python|javascript|typescript|react|flutter|backend|frontend|java|c\+\+|bug|git|api|thuật toán|leetcode', caseSensitive: false).hasMatch(lower)) {
      final mins = _pick([30, 40, 45, 50]);
      final lines = _pick([40, 60, 80, 100]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Đọc 1 bài viết kỹ thuật hoặc tài liệu về $topic',
            subtitle: 'Chuẩn bị kiến trúc vững vàng và ghi chép 3 thuật ngữ cốt lõi',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e2',
            title: 'Review và refactor 20 dòng code sạch sẽ theo Clean Code',
            subtitle: 'Xóa code thừa, đặt tên biến chuẩn ngữ nghĩa',
            xp: 95,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e3',
            title: 'Khởi động tư duy: Đọc hiểu 1 mẫu thiết kế (Design Pattern)',
            subtitle: 'Phân tích cách vận dụng pattern vào bài toán thực tế',
            xp: 100,
            spiritStones: 14,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Tập trung code chuyên sâu $mins phút về $topic',
            subtitle: 'Ngắt toàn bộ thông báo mạng xã hội, duy trì trạng thái dòng chảy',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm2',
            title: 'Viết ít nhất $lines dòng code chuẩn cấu trúc và tự test',
            subtitle: 'Đảm bảo code chạy ổn định không có lỗi biên dịch',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm3',
            title: 'Giải quyết triệt để 1 bài toán thuật toán LeetCode hoặc 2 issue',
            subtitle: 'Tối ưu độ phức tạp thời gian O(n) và không gian bộ nhớ',
            xp: 240,
            spiritStones: 30,
            difficulty: 'MEDIUM',
            icon: Icons.code_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Bứt phá: Hoàn thiện 1 module chức năng của $topic',
            subtitle: 'Kiểm thử toàn diện, tối ưu hiệu năng và commit Git bài bản',
            xp: 410,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Sprint lập trình 60 phút: Debug triệt để và viết tài liệu API',
            subtitle: 'Đạt độ bao phủ kiểm thử cao và hoàn tất tài liệu sạch sẽ',
            xp: 430,
            spiritStones: 55,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 2. Ngoại ngữ (Tiếng Anh, IELTS, TOEIC, v.v.)
    if (RegExp(r'tiếng anh|english|ielts|toeic|tiếng nhật|tiếng hàn|tiếng trung|ngoại ngữ|ngữ pháp|phát âm|từ vựng', caseSensitive: false).hasMatch(lower)) {
      final vocabCount = _pick([15, 20, 25, 30]);
      final listenMins = _pick([20, 25, 30]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Học $vocabCount từ vựng mới bằng phương pháp lặp lại ngắt quãng (SRS)',
            subtitle: 'Ứng dụng flashcard và đặt câu ví dụ trực tiếp với từng từ',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e2',
            title: 'Luyện phát âm chuẩn IPA 15 phút với từ điển giọng bản xứ',
            subtitle: 'Ghi âm lại giọng đọc và so sánh ngữ điệu chuẩn xác',
            xp: 95,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e3',
            title: 'Ôn tập 25 từ vựng cũ và viết thành 5 câu văn hoàn chỉnh',
            subtitle: 'Củng cố trí nhớ dài hạn, phản xạ đặt câu tự nhiên',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Luyện nghe podcast / video $listenMins phút kết hợp nhại giọng (Shadowing)',
            subtitle: 'Tập trung phản xạ tự nhiên, nhại đúng ngữ điệu và trọng âm',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'm2',
            title: 'Đọc hiểu sâu 1 bài báo chuyên ngành và tóm tắt lại bằng ngoại ngữ',
            subtitle: 'Gạch chân từ khóa và ghi lại luận điểm chính',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'm3',
            title: 'Luyện giao tiếp phản xạ 25 phút qua ứng dụng hoặc tự nói trước gương',
            subtitle: 'Không dừng lại dịch sang tiếng mẹ đẻ, bật phản xạ tự nhiên',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.headset_mic_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Viết 1 bài luận 200 chữ hoặc luyện nói liên tục 15 phút ghi âm',
            subtitle: 'Kiểm tra lỗi ngữ pháp và phân tích cặn kẽ nguyên nhân câu sai',
            xp: 410,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Giải trọn vẹn 1 đề thi thử trong điều kiện bấm giờ nghiêm ngặt',
            subtitle: 'Đo lường năng lực thực chiến, không tra cứu tài liệu',
            xp: 430,
            spiritStones: 55,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 3. Chạy bộ / Đi bộ / Cardio sức bền
    if (RegExp(r'chạy bộ|chạy|marathon|chay|cardio|nhảy dây|đi bộ|pace|bước chân', caseSensitive: false).hasMatch(lower)) {
      final km = _pick([3, 4, 5]);
      final jumpRopes = _pick([250, 300, 350]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Nhảy dây $jumpRopes cái nhịp nhàng',
            subtitle: 'Kích hoạt nhịp tim và điều hòa nhịp thở đều đặn',
            xp: 85,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'e2',
            title: 'Đi bộ nhanh 1.5km hoặc chạy nhẹ 10 phút',
            subtitle: 'Làm nóng khớp gối và cổ chân, kích thích tuần hoàn',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'e3',
            title: 'Squat bật nhảy (Jump Squats) 30 lần',
            subtitle: 'Tăng cường sức bật của cơ đùi và khớp gối',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.accessibility_new_rounded,
            iconColor: const Color(0xFF34D399),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Chạy bộ liên tục ${km}km với nhịp tim ổn định Zone 2',
            subtitle: 'Duy trì sải chân đều đặn, thở sâu nhịp nhàng bằng mũi và miệng',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          QuestItem(
            id: 'm2',
            title: 'Gập bụng 50 lần kết hợp bật nhảy Burpees 20 cái',
            subtitle: 'Đốt cháy năng lượng toàn thân, siết chặt cơ lõi',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          QuestItem(
            id: 'm3',
            title: 'Chạy biến tốc: 6 hiệp chạy nhanh 1 phút xen kẽ đi bộ',
            subtitle: 'Khai phá sức chịu đựng yếm khí và bứt tốc',
            xp: 240,
            spiritStones: 30,
            difficulty: 'MEDIUM',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Chinh phục cự ly dài hoặc chạy dốc 6km bứt phá giới hạn',
            subtitle: 'Kiên trì hoàn thành cự ly mà không dừng lại, ý chí thợ săn quật cường',
            xp: 420,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Thử thách Cardio: Nhảy dây 500 cái & Chạy bền 35 phút',
            subtitle: 'Bứt phá sức chịu đựng cực hạn, tiêu hao calo khủng',
            xp: 440,
            spiritStones: 55,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 4. Thể dục / Thể hình / Gym / Gập bụng / Chống đẩy / Calisthenics
    if (RegExp(r'thể dục|tập thể dục|gym|thể hình|tăng cơ|tạ|xà đơn|chống đẩy|hít đất|squat|gập bụng|cơ bụng|six pack|thể lực|calisthenics|workout|luyện tập', caseSensitive: false).hasMatch(lower)) {
      final pushCount = _pick([40, 50, 60]);
      final squatCount = _pick([50, 60, 70]);
      final situpEasy = _pick([30, 40, 45]);
      final situpMed = _pick([60, 70, 80]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Gập bụng (Sit-ups) $situpEasy lần',
            subtitle: 'Chia 2-3 hiệp, siết chặt cơ bụng chuẩn form',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.accessibility_new_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
          QuestItem(
            id: 'e2',
            title: 'Chống đẩy (Push-ups) 25 cái chuẩn form',
            subtitle: 'Ngực chạm sát đất, siết cơ lõi không võng lưng',
            xp: 95,
            spiritStones: 14,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
          QuestItem(
            id: 'e3',
            title: 'Squat (Gánh đùi) 40 cái',
            subtitle: 'Đùi song song mặt đất, trọng tâm dồn gót chân',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.accessibility_new_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
          QuestItem(
            id: 'e4',
            title: 'Plank siết chặt cơ bụng 60 giây',
            subtitle: 'Thẳng lưng, siết mông và cơ bụng liên tục',
            xp: 95,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Gập bụng (Sit-ups) $situpMed lần chia 3 hiệp',
            subtitle: 'Chia làm 3 hiệp, siết cơ bụng ở điểm cao nhất',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          QuestItem(
            id: 'm2',
            title: 'Chống đẩy $pushCount cái & Squat $squatCount cái chuẩn form',
            subtitle: 'Chia làm 3-4 hiệp, kiểm soát chuyển động lúc hạ người',
            xp: 240,
            spiritStones: 30,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          QuestItem(
            id: 'm3',
            title: 'Gập bụng đạp xe (Bicycle Crunches) 60 lần',
            subtitle: 'Khai mở cơ liên sườn và rãnh bụng',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.accessibility_new_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          QuestItem(
            id: 'm4',
            title: 'Tập cơ trọng tâm: Plank 3 hiệp (mỗi hiệp 60s) & 40 cái gập bụng',
            subtitle: 'Gia cố cơ lõi vững chắc như bàn thạch',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Thử thách cực hạn: 100 lần gập bụng (Sit-ups)',
            subtitle: 'Chạm ngưỡng thất bại để bứt phá thể chất, ý chí thợ săn thép',
            xp: 420,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Thử thách cực hạn: 100 cái Squat & 50 cái chống đẩy',
            subtitle: 'Bứt phá giới hạn chịu đựng cơ bắp',
            xp: 430,
            spiritStones: 52,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h3',
            title: 'Chinh phục 15 cái kéo xà đơn (Pull-ups) hoặc 70 cái chống đẩy',
            subtitle: 'Ý chí thợ săn quật cường, tôi luyện sức mạnh tuyệt đỉnh',
            xp: 440,
            spiritStones: 55,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 5. Tăng cân / Bulk
    if (RegExp(r'tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân', caseSensitive: false).hasMatch(lower)) {
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Squat (Gánh đùi) 35 cái & Chống đẩy 20 cái kích thích cơ',
            subtitle: 'Kích hoạt các nhóm cơ lớn giúp cơ thể hấp thu dưỡng chất tối đa',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          QuestItem(
            id: 'e2',
            title: 'Gập bụng 35 lần & Plank 45 giây kích thích tiêu hóa',
            subtitle: 'Kích thích đường ruột hấp thu tối đa dưỡng chất',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.accessibility_new_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          QuestItem(
            id: 'e3',
            title: 'Chống đẩy ngực cao 25 cái khởi động các khớp xương',
            subtitle: 'Làm nóng gân cốt chuẩn bị cho phiên tập tăng cơ',
            xp: 95,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF10B981),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Tập kháng lực 40 phút: 50 cái Squat, 40 cái chống đẩy, 50 lần gập bụng',
            subtitle: 'Tập nặng để chuyển hóa calo thặng dư thành cơ nạc',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
          QuestItem(
            id: 'm2',
            title: 'Tập tạ / Calisthenics 4 hiệp mỗi bài: Chống đẩy kim cương 30 cái, Squat 60 cái',
            subtitle: 'Kích thích phì đại sợi cơ (Hypertrophy)',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
          QuestItem(
            id: 'm3',
            title: 'Kéo xà đơn 10 cái & Chống đẩy dốc xuống (Decline Push-ups) 35 cái',
            subtitle: 'Xây dựng bề dày lồng ngực và lưng xô',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFF2C465),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Thử thách thể lực: 8 hiệp Squat tăng tạ hoặc 80 cái Squat bodyweight',
            subtitle: 'Chạm ngưỡng mỏi cơ bắp, kích thích tối đa hormone phát triển',
            xp: 400,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Buổi tập toàn thân bứt phá: 60 cái chống đẩy, 80 cái squat, 60 lần gập bụng',
            subtitle: 'Tập chạm ngưỡng kiệt sức cơ nạc, kích hoạt siêu bù đắp dinh dưỡng',
            xp: 420,
            spiritStones: 52,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 6. Giảm cân / Giảm mỡ / Siết cơ
    if (RegExp(r'giảm cân|giảm mỡ|giam can|giam mo|siết cơ|thâm hụt calo|diet|ăn kiêng', caseSensitive: false).hasMatch(lower)) {
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Gập bụng (Sit-ups) 40 lần & Plank 60 giây siết eo',
            subtitle: 'Siết chặt cơ bụng, kích hoạt tiêu hao năng lượng tức thì',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFEF4444),
          ),
          QuestItem(
            id: 'e2',
            title: 'Nhảy dây 300 cái đốt mỡ toàn thân',
            subtitle: 'Duy trì nhịp nhảy đều đặn, kích hoạt nhịp tim đốt mỡ',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFFEF4444),
          ),
          QuestItem(
            id: 'e3',
            title: 'Squat gánh đùi 35 cái & 25 cái chống đẩy đốt calo',
            subtitle: 'Huy động nhóm cơ lớn tiêu hao năng lượng nhanh',
            xp: 95,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFFEF4444),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Vận động đốt mỡ: Đạt 8.000 bước chân hoặc 60 lần gập bụng đạp xe',
            subtitle: 'Gia tăng tiêu hao năng lượng, thắt chặt vòng 2',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'm2',
            title: 'Chạy bộ 3.0 km hoặc 30 cái Burpees đốt mỡ',
            subtitle: 'Duy trì cường độ cao ngắt quãng, tiêu hao calo kéo dài',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'm3',
            title: 'Tổ hợp cơ bụng: Plank 3 hiệp 60s & 50 lần nâng chân Leg Raises',
            subtitle: 'Siết chặt thành bụng dưới, giảm mỡ nội tạng',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF34D399),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Tổ hợp đốt mỡ cực hạn: 80 lần gập bụng, 60 cái squat, 30 cái burpees',
            subtitle: 'Tập liên hoàn đốt cháy calo cực đại, cơ bụng săn chắc',
            xp: 410,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Nhảy dây 600 cái & Plank 3 hiệp (mỗi hiệp 60 giây)',
            subtitle: 'Khai hỏa động cơ tiêu hao năng lượng, siết cơ lõi',
            xp: 420,
            spiritStones: 52,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 7. Đọc sách / Học tập / Nghiên cứu / Tri thức
    if (RegExp(r'đọc sách|doc sach|sách|đọc|ôn thi|học tập|nghiên cứu|kiến thức', caseSensitive: false).hasMatch(lower)) {
      final pages = _pick([20, 25, 30, 35]);
      final studyMins = _pick([40, 45, 50, 60]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Đọc tập trung $pages trang sách không chạm vào điện thoại',
            subtitle: 'Gạch chân và đánh dấu các luận điểm đắt giá nhất',
            xp: 85,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e2',
            title: 'Đúc kết 3 bài học tâm đắc nhất vào sổ tay tư duy',
            subtitle: 'Ghi chép cô đọng để có thể áp dụng ngay vào đời sống',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'e3',
            title: 'Đọc 15 trang sách và giải thích 1 khái niệm cốt lõi bằng lời của mình',
            subtitle: 'Nắm vững bản chất kiến thức trước khi đi tiếp',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Phiên học sâu Deep Work $studyMins phút theo phương pháp Pomodoro',
            subtitle: 'Ngắt kết nối mọi thông báo gây xao nhãng, tập trung 100% công suất',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFFF59E0B),
          ),
          QuestItem(
            id: 'm2',
            title: 'Vẽ sơ đồ tư duy (Mindmap) hệ thống hóa toàn bộ chương sách vừa đọc',
            subtitle: 'Hệ thống hóa kiến thức thành mạng lưới liên kết',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
          QuestItem(
            id: 'm3',
            title: 'Giải 3 bài tập tư duy hoặc viết 2 trang phân tích chuyên đề',
            subtitle: 'Biến tri thức thành kỹ năng thực chiến',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Áp dụng kỹ thuật Feynman: Tự giải thích lại chủ đề một cách đơn giản',
            subtitle: 'Xây dựng góc nhìn độc lập, tôi luyện tư duy phản biện sắc bén',
            xp: 410,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Viết bài tổng quan phản biện hoặc phân tích chuyên sâu 400 chữ',
            subtitle: 'Đóng gói tri thức thành bài nghiên cứu hoàn chỉnh',
            xp: 430,
            spiritStones: 55,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 8. Nghệ thuật / Âm nhạc / Đàn / Vẽ
    if (RegExp(r'đàn|guitar|piano|nhạc|hát|vocal|vẽ|hội họa|sketch|thiết kế|art', caseSensitive: false).hasMatch(lower)) {
      final practiceMins = _pick([30, 40, 45]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Luyện ngón tay, gam âm giai hoặc phác thảo cơ bản 15 phút ($topic)',
            subtitle: 'Xây dựng độ nhạy cảm và sự dẻo dai của đôi tay',
            xp: 85,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'e2',
            title: 'Ký họa nhanh 3 mẫu hoặc tập luyện 4 hợp âm cơ bản',
            subtitle: 'Rèn luyện phản xạ thị giác và trí nhớ cơ bắp',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.music_note_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'e3',
            title: 'Nghe và phân tích cấu trúc 1 tác phẩm mẫu 20 phút',
            subtitle: 'Cảm thụ tiết tấu, hòa âm và bố cục màu sắc',
            xp: 90,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Thực hành liên tục $practiceMins phút tác phẩm đang theo đuổi',
            subtitle: 'Tập chậm từng đoạn khó, dùng máy đập nhịp (metronome) nếu cần',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.music_note_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm2',
            title: 'Hoàn thiện 50% chi tiết bức vẽ hoặc đi trọn vẹn nửa bài nhạc',
            subtitle: 'Kiên trì trau chuốt từng đường nét và nốt nhạc',
            xp: 230,
            spiritStones: 28,
            difficulty: 'MEDIUM',
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm3',
            title: 'Thử thách biến tấu: Sáng tác hoặc ngẫu hứng 1 giai điệu/bản phác thảo 30 phút',
            subtitle: 'Phóng thích sức sáng tạo tự do không rào cản',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.music_note_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Thu âm hoặc hoàn thiện trọn vẹn 1 tác phẩm không ngắt quãng',
            subtitle: 'Nghiệm thu chất lượng tác phẩm, đánh giá sự tiến bộ rõ rệt',
            xp: 400,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Bứt phá kỹ thuật: Chinh phục trọn vẹn đoạn nhạc/kỹ thuật khó nhất',
            subtitle: 'Vượt qua nút thắt cổ chai kỹ năng nghệ thuật',
            xp: 420,
            spiritStones: 52,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 9. Tài chính / Tiết kiệm / Đầu tư
    if (RegExp(r'tiết kiệm|tài chính|đầu tư|tiền|chi tiêu|chứng khoán|ngân sách', caseSensitive: false).hasMatch(lower)) {
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Ghi chép chính xác 100% tất cả các khoản chi tiêu trong ngày',
            subtitle: 'Phân loại chi tiêu thành Cần thiết (Needs) và Mong muốn (Wants)',
            xp: 80,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'e2',
            title: 'Kiểm kê số dư toàn bộ tài khoản và cập nhật bảng ngân sách',
            subtitle: 'Nắm chắc hiện trạng tài chính cá nhân không mập mờ',
            xp: 85,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF34D399),
          ),
          QuestItem(
            id: 'e3',
            title: 'Học 1 thuật ngữ tài chính/đầu tư cốt lõi (P/E, ROI, Lạm phát)',
            subtitle: 'Tích lũy kiến thức nền tảng tài chính thông minh',
            xp: 85,
            spiritStones: 12,
            difficulty: 'EASY',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF34D399),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Đọc 1 báo cáo tài chính hoặc phân tích kinh tế chuyên sâu 30 phút',
            subtitle: 'Nâng cao tư duy quản trị dòng tiền và tích lũy tài sản dài hạn',
            xp: 210,
            spiritStones: 25,
            difficulty: 'MEDIUM',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm2',
            title: 'Lập kế hoạch phân bổ dòng tiền tháng tới theo quy tắc 50/30/20',
            subtitle: 'Thiết lập kỷ luật tiền tệ sắt đá trước khi nhận thu nhập',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
          QuestItem(
            id: 'm3',
            title: 'Tìm hiểu và phân tích 1 cơ hội đầu tư hoặc mô hình gia tăng thu nhập',
            subtitle: 'Mở rộng nguồn thu, không phụ thuộc vào một nguồn duy nhất',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF38BDF8),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Cắt giảm triệt để 1 khoản chi phí thừa & chuyển ngay vào quỹ tiết kiệm',
            subtitle: 'Kỷ luật tài chính sắt đá tạo nên sự tự do đích thực',
            xp: 390,
            spiritStones: 48,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Thiết lập tự động trích lập quỹ khẩn cấp hoặc đầu tư dài hạn',
            subtitle: 'Xây dựng pháo đài tài chính kiên cố phòng ngừa rủi ro',
            xp: 410,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 10. Thiền định / Tâm thức / Giấc ngủ
    if (RegExp(r'thiền|tĩnh tâm|ngủ sớm|dậy sớm|mindfulness|tâm thức|thư giãn', caseSensitive: false).hasMatch(lower)) {
      final medMins = _pick([10, 15, 20]);
      return _buildQuestsFromPools(
        now: now,
        easyPool: [
          QuestItem(
            id: 'e1',
            title: 'Ngồi thiền thở sâu tĩnh tâm $medMins phút vào đầu ngày',
            subtitle: 'Quan sát hơi thở tự nhiên, thanh lọc tâm trí khỏi âu lo',
            xp: 85,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.self_improvement_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'e2',
            title: 'Đi bộ chánh niệm 15 phút không dùng tai nghe hay điện thoại',
            subtitle: 'Cảm nhận từng bước chân chạm đất, đưa tâm về với thân',
            xp: 85,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
          QuestItem(
            id: 'e3',
            title: 'Viết ra 3 điều biết ơn sâu sắc vào nhật ký tâm thức',
            subtitle: 'Nuôi dưỡng hạt giống an lạc và năng lượng tích cực',
            xp: 80,
            spiritStones: 10,
            difficulty: 'EASY',
            icon: Icons.self_improvement_rounded,
            iconColor: const Color(0xFFA78BFA),
          ),
        ],
        medPool: [
          QuestItem(
            id: 'm1',
            title: 'Dọn sạch góc làm việc & ngắt màn hình xanh 45 phút trước khi ngủ',
            subtitle: 'Tạo không gian tĩnh lặng, đưa não bộ vào trạng thái nghỉ ngơi',
            xp: 200,
            spiritStones: 24,
            difficulty: 'MEDIUM',
            icon: Icons.bedtime_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'm2',
            title: 'Thực hành quét toàn bộ cơ thể (Body Scan) 20 phút trước khi ngủ',
            subtitle: 'Giải phóng toàn bộ căng thẳng tích tụ ở các nhóm cơ',
            xp: 210,
            spiritStones: 25,
            difficulty: 'MEDIUM',
            icon: Icons.self_improvement_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
          QuestItem(
            id: 'm3',
            title: 'Thiền định tĩnh lặng 30 phút trong không gian yên tĩnh',
            subtitle: 'Đạt tới trạng thái định tâm sâu sắc, bình thản trước biến động',
            xp: 220,
            spiritStones: 26,
            difficulty: 'MEDIUM',
            icon: Icons.self_improvement_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
        ],
        hardPool: [
          QuestItem(
            id: 'h1',
            title: 'Lên giường trước 22h30 và thức giấc đón nắng mai đúng giờ báo thức',
            subtitle: 'Thiết lập nhịp sinh học hoàn hảo, duy trì tinh thần minh mẫn',
            xp: 380,
            spiritStones: 46,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
          QuestItem(
            id: 'h2',
            title: 'Thử thách 1 ngày nói không với than vãn và mạng xã hội vô bổ',
            subtitle: 'Bảo vệ nguồn năng lượng tâm thức tinh khiết',
            xp: 400,
            spiritStones: 50,
            difficulty: 'HARD',
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFFBBF24),
          ),
        ],
      );
    }

    // 11. Mặc định Đa Lĩnh Vực Thông Minh (Tự động thích ứng với mục tiêu của người dùng)
    final studyMins = _pick([30, 45, 50]);
    final actionMins = _pick([40, 50, 60]);
    return _buildQuestsFromPools(
      now: now,
      easyPool: [
        QuestItem(
          id: 'e1',
          title: 'Nghiên cứu tài liệu & lập danh mục hành động cho: $topic',
          subtitle: 'Chuẩn bị đầy đủ công cụ và môi trường trước khi thực hiện',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'e2',
          title: 'Khởi động 15 phút: Thực hiện bước vi mô đầu tiên của $topic',
          subtitle: 'Phá vỡ sức ỳ ban đầu bằng hành động nhỏ dứt khoát',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'e3',
          title: 'Gập bụng 35 lần hoặc Chống đẩy 20 cái kích hoạt thể lực rèn luyện $topic',
          subtitle: 'Thể chất mạnh mẽ là nền tảng cho mọi ý chí',
          xp: 95,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
      ],
      medPool: [
        QuestItem(
          id: 'm1',
          title: 'Tập trung sâu $studyMins phút thực hiện nhiệm vụ trọng tâm: $topic',
          subtitle: 'Loại bỏ hoàn toàn thông báo gây phân tâm, duy trì trạng thái dòng chảy',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'm2',
          title: 'Thực hành nghiêm túc $actionMins phút nâng cao kỹ năng: $topic',
          subtitle: 'Chăm chỉ tích lũy lượng biến thành chất',
          xp: 230,
          spiritStones: 28,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'm3',
          title: 'Giải quyết dứt điểm 1 khâu quan trọng nhất trong kế hoạch $topic',
          subtitle: 'Không trì hoãn những việc khó, dũng mãnh đối mặt',
          xp: 230,
          spiritStones: 28,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
      ],
      hardPool: [
        QuestItem(
          id: 'h1',
          title: 'Bứt phá giới hạn: Hoàn tất 1 cột mốc quan trọng của $topic',
          subtitle: 'Đánh giá kết quả bằng số liệu cụ thể, không chấp nhận sự trì hoãn',
          xp: 410,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
        QuestItem(
          id: 'h2',
          title: 'Thử thách cực hạn: Tổng kết ngày và tối ưu hóa quy trình rèn luyện $topic',
          subtitle: 'Không ngừng nâng cấp bản thân lên một tầm cao mới',
          xp: 420,
          spiritStones: 52,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ],
    );
  }
}
