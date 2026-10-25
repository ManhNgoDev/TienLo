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

  static List<QuestItem> analyzeGoalAndCreateQuests(String goalText) {
    final lower = goalText.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch;
    final topic = _cleanTopic(goalText);

    // 1. Lập trình / Công nghệ / Code
    if (RegExp(r'code|lập trình|dev|python|javascript|typescript|react|flutter|backend|frontend|java|c\+\+|bug|git|api|thuật toán|leetcode', caseSensitive: false).hasMatch(lower)) {
      final mins = _pick([30, 40, 45, 50]);
      final lines = _pick([40, 60, 80, 100]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: _pick([
            'Đọc 1 bài viết kỹ thuật hoặc tài liệu về $topic',
            'Review và refactor 20 dòng code sạch sẽ theo Clean Code',
            'Khởi động tư duy: Đọc hiểu 1 mẫu thiết kế (Design Pattern)',
          ]),
          subtitle: 'Chuẩn bị kiến trúc vững vàng và ghi chép 3 thuật ngữ cốt lõi',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: _pick([
            'Tập trung code chuyên sâu $mins phút về $topic',
            'Viết ít nhất $lines dòng code chuẩn cấu trúc và tự test',
            'Giải quyết triệt để 1 bài toán thuật toán LeetCode hoặc 2 issue',
          ]),
          subtitle: 'Ngắt toàn bộ thông báo mạng xã hội, duy trì trạng thái dòng chảy',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.code_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: _pick([
            'Bứt phá: Hoàn thiện 1 module chức năng của $topic',
            'Sprint lập trình 60 phút: Debug triệt để và viết tài liệu API',
          ]),
          subtitle: 'Kiểm thử toàn diện, tối ưu hiệu năng và commit Git bài bản',
          xp: 410,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 2. Ngoại ngữ (Tiếng Anh, IELTS, TOEIC, v.v.)
    if (RegExp(r'tiếng anh|english|ielts|toeic|tiếng nhật|tiếng hàn|tiếng trung|ngoại ngữ|ngữ pháp|phát âm|từ vựng', caseSensitive: false).hasMatch(lower)) {
      final vocabCount = _pick([15, 20, 25, 30]);
      final listenMins = _pick([20, 25, 30]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: _pick([
            'Học $vocabCount từ vựng mới bằng phương pháp lặp lại ngắt quãng (SRS)',
            'Luyện phát âm chuẩn IPA 15 phút với từ điển giọng bản xứ',
          ]),
          subtitle: 'Ứng dụng flashcard và đặt câu ví dụ trực tiếp với từng từ',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: _pick([
            'Luyện nghe podcast / video $listenMins phút kết hợp nhại giọng (Shadowing)',
            'Đọc hiểu sâu 1 bài báo chuyên ngành và tóm tắt lại bằng ngoại ngữ',
          ]),
          subtitle: 'Tập trung phản xạ tự nhiên, nhại đúng ngữ điệu và trọng âm',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.headset_mic_rounded,
          iconColor: const Color(0xFFA78BFA),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: _pick([
            'Viết 1 bài luận 200 chữ hoặc luyện nói liên tục 15 phút ghi âm',
            'Giải trọn vẹn 1 đề thi thử trong điều kiện bấm giờ nghiêm ngặt',
          ]),
          subtitle: 'Kiểm tra lỗi ngữ pháp và phân tích cặn kẽ nguyên nhân câu sai',
          xp: 410,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 3. Chạy bộ / Đi bộ / Cardio sức bền
    if (RegExp(r'chạy bộ|chạy|marathon|chay|cardio|nhảy dây|đi bộ|pace', caseSensitive: false).hasMatch(lower)) {
      final km = _pick([3, 4, 5]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: _pick([
            'Khởi động kỹ khớp cổ chân, đầu gối và cơ đùi 10 phút',
            'Đi bộ nhanh 1.5km hoặc nhảy dây 250 cái nhịp nhàng',
          ]),
          subtitle: 'Làm nóng nhịp tim để hạn chế tối đa nguy cơ chấn thương',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.directions_walk_rounded,
          iconColor: const Color(0xFF34D399),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: _pick([
            'Chạy bộ liên tục ${km}km với nhịp tim ổn định Zone 2',
            'Chạy biến tốc: 6 hiệp chạy nhanh 1 phút xen kẽ đi bộ',
          ]),
          subtitle: 'Duy trì sải chân đều đặn, thở sâu nhịp nhàng bằng mũi và miệng',
          xp: 230,
          spiritStones: 28,
          difficulty: 'MEDIUM',
          icon: Icons.directions_run_rounded,
          iconColor: const Color(0xFF10B981),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: _pick([
            'Chinh phục cự ly dài hoặc chạy dốc 6km bứt phá giới hạn',
            'Chạy bền 45 phút liên tục kết hợp ép dẻo giãn cơ sâu sau chạy',
          ]),
          subtitle: 'Kiên trì hoàn thành cự ly mà không dừng lại, ý chí thợ săn quật cường',
          xp: 420,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 4. Thể hình / Gym / Tăng cơ / Calisthenics
    if (RegExp(r'gym|thể hình|tăng cơ|tạ|xà đơn|chống đẩy|hít đất|squat|cơ bụng|six pack|thể lực', caseSensitive: false).hasMatch(lower)) {
      final pushCount = _pick([40, 50, 60]);
      final squatCount = _pick([60, 70, 80]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: _pick([
            'Khởi động làm nóng toàn thân & xoay khớp chuyên sâu 12 phút',
            'Giãn cơ tĩnh 15 phút & nạp đủ 25g protein sau buổi tập',
          ]),
          subtitle: 'Kích hoạt hệ thần kinh trung ương và các sợi cơ mục tiêu',
          xp: 85,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.accessibility_new_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: _pick([
            'Chống đẩy $pushCount cái & Squat $squatCount cái chuẩn form',
            'Tập cơ trọng tâm: Plank 3 hiệp (mỗi hiệp 60s) & Gập bụng 50 cái',
          ]),
          subtitle: 'Chia làm 4 hiệp, kiểm soát chuyển động lúc hạ người',
          xp: 230,
          spiritStones: 28,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: _pick([
            'Thử thách cực hạn: 100 cái Squat hoặc 20 cái kéo xà đơn',
            'Buổi tập tạ cường độ cao 50 phút bứt phá giới hạn tạ',
          ]),
          subtitle: 'Tăng mức tạ lũy tiến (Progressive Overload), chạm ngưỡng thất bại',
          xp: 420,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 5. Tăng cân / Bulk
    if (RegExp(r'tăng\s*(thêm)?\s*(\d+)?\s*(cân|kg|ký)|bulk|tăng\s*cân', caseSensitive: false).hasMatch(lower)) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Bổ sung thêm 1 bữa phụ giàu protein và tinh bột tốt',
          subtitle: 'Sữa chua, chuối, hạt dinh dưỡng hoặc yến mạch giữa các bữa chính',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFF10B981),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập kháng lực kích thích cơ bắp 40 phút (Squat, chống đẩy)',
          subtitle: 'Tập nặng để chuyển hóa calo dư thừa thành cơ nạc thay vì mỡ',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Đạt thặng dư 400-500 kcal trong ngày & ngủ đủ 8 tiếng',
          subtitle: 'Ngủ sâu phục hồi hormone tăng trưởng giúp đồng hóa tối đa',
          xp: 390,
          spiritStones: 45,
          difficulty: 'HARD',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    // 6. Giảm cân / Giảm mỡ / Siết cơ
    if (RegExp(r'giảm cân|giảm mỡ|giam can|giam mo|siết cơ|thâm hụt calo|diet|ăn kiêng', caseSensitive: false).hasMatch(lower)) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Cắt giảm 100% đường tinh luyện, nước ngọt có ga và bánh kẹo hôm nay',
          subtitle: 'Ổn định lượng đường huyết, chấm dứt cảm giác thèm ăn vặt',
          xp: 90,
          spiritStones: 12,
          difficulty: 'EASY',
          icon: Icons.no_food_rounded,
          iconColor: const Color(0xFFEF4444),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Vận động đốt mỡ: Đạt 8.000 bước chân hoặc 30 phút cardio',
          subtitle: 'Gia tăng tiêu hao năng lượng ngoài tập luyện (NEAT)',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.directions_walk_rounded,
          iconColor: const Color(0xFF34D399),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Áp dụng nhịn ăn gián đoạn 16/8 và không ăn sau 20h tối',
          subtitle: 'Tạo cửa sổ thâm hụt calo giúp cơ thể dùng mỡ thừa làm năng lượng',
          xp: 400,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 7. Đọc sách / Học tập / Nghiên cứu / Tri thức
    if (RegExp(r'đọc sách|doc sach|sách|đọc|ôn thi|học tập|nghiên cứu|kiến thức', caseSensitive: false).hasMatch(lower)) {
      final pages = _pick([20, 25, 30, 35]);
      final studyMins = _pick([40, 45, 50, 60]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: _pick([
            'Đọc tập trung $pages trang sách không chạm vào điện thoại',
            'Đúc kết 3 bài học tâm đắc nhất vào sổ tay tư duy',
          ]),
          subtitle: 'Gạch chân và đánh dấu các luận điểm đắt giá nhất',
          xp: 85,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: _pick([
            'Phiên học sâu Deep Work $studyMins phút theo phương pháp Pomodoro',
            'Vẽ sơ đồ tư duy (Mindmap) hệ thống hóa toàn bộ chương sách vừa đọc',
          ]),
          subtitle: 'Ngắt kết nối mọi thông báo gây xao nhãng, tập trung 100% công suất',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: _pick([
            'Áp dụng kỹ thuật Feynman: Tự giải thích lại chủ đề một cách đơn giản',
            'Viết bài tổng quan phản biện hoặc phân tích chuyên sâu 400 chữ',
          ]),
          subtitle: 'Xây dựng góc nhìn độc lập, tôi luyện tư duy phản biện sắc bén',
          xp: 410,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 8. Nghệ thuật / Âm nhạc / Đàn / Vẽ
    if (RegExp(r'đàn|guitar|piano|nhạc|hát|vocal|vẽ|hội họa|sketch|thiết kế|art', caseSensitive: false).hasMatch(lower)) {
      final practiceMins = _pick([30, 40, 45]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Luyện ngón tay, gam âm giai hoặc phác thảo cơ bản 15 phút ($topic)',
          subtitle: 'Xây dựng độ nhạy cảm và sự dẻo dai của đôi tay',
          xp: 85,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.palette_rounded,
          iconColor: const Color(0xFFA78BFA),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Thực hành liên tục $practiceMins phút tác phẩm đang theo đuổi',
          subtitle: 'Tập chậm từng đoạn khó, dùng máy đập nhịp (metronome) nếu cần',
          xp: 220,
          spiritStones: 26,
          difficulty: 'MEDIUM',
          icon: Icons.music_note_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Thu âm hoặc hoàn thiện trọn vẹn 1 tác phẩm không ngắt quãng',
          subtitle: 'Nghiệm thu chất lượng tác phẩm, đánh giá sự tiến bộ rõ rệt',
          xp: 400,
          spiritStones: 50,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 9. Tài chính / Tiết kiệm / Đầu tư
    if (RegExp(r'tiết kiệm|tài chính|đầu tư|tiền|chi tiêu|chứng khoán|ngân sách', caseSensitive: false).hasMatch(lower)) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Ghi chép chính xác 100% tất cả các khoản chi tiêu trong ngày',
          subtitle: 'Phân loại chi tiêu thành Cần thiết (Needs) và Mong muốn (Wants)',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF34D399),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Đọc 1 báo cáo tài chính hoặc phân tích kinh tế chuyên sâu 30 phút',
          subtitle: 'Nâng cao tư duy quản trị dòng tiền và tích lũy tài sản dài hạn',
          xp: 210,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Cắt giảm triệt để 1 khoản chi phí thừa & chuyển ngay vào quỹ tiết kiệm',
          subtitle: 'Kỷ luật tài chính sắt đá tạo nên sự tự do đích thực',
          xp: 390,
          spiritStones: 48,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 10. Thiền định / Tâm thức / Giấc ngủ
    if (RegExp(r'thiền|tĩnh tâm|ngủ sớm|dậy sớm|mindfulness|tâm thức|thư giãn', caseSensitive: false).hasMatch(lower)) {
      final medMins = _pick([10, 15, 20]);
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Ngồi thiền thở sâu tĩnh tâm $medMins phút vào đầu ngày',
          subtitle: 'Quan sát hơi thở tự nhiên, thanh lọc tâm trí khỏi âu lo',
          xp: 85,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.self_improvement_rounded,
          iconColor: const Color(0xFFA78BFA),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Dọn sạch góc làm việc & ngắt màn hình xanh 45 phút trước khi ngủ',
          subtitle: 'Tạo không gian tĩnh lặng, đưa não bộ vào trạng thái nghỉ ngơi',
          xp: 200,
          spiritStones: 24,
          difficulty: 'MEDIUM',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF60A5FA),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Lên giường trước 22h30 và thức giấc đón nắng mai đúng giờ báo thức',
          subtitle: 'Thiết lập nhịp sinh học hoàn hảo, duy trì tinh thần minh mẫn',
          xp: 380,
          spiritStones: 46,
          difficulty: 'HARD',
          icon: Icons.military_tech_rounded,
          iconColor: const Color(0xFFFBBF24),
        ),
      ];
    }

    // 11. Mặc định Đa Lĩnh Vực Thông Minh (Tự động thích ứng với mục tiêu của người dùng)
    final studyMins = _pick([30, 45, 50]);
    final actionMins = _pick([40, 50, 60]);
    return [
      QuestItem(
        id: 'q-$now-1',
        title: _pick([
          'Nghiên cứu tài liệu & lập danh mục hành động cho: $topic',
          'Khởi động 15 phút: Thực hiện bước vi mô đầu tiên của $topic',
        ]),
        subtitle: 'Chuẩn bị đầy đủ công cụ và môi trường trước khi thực hiện',
        xp: 90,
        spiritStones: 12,
        difficulty: 'EASY',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF60A5FA),
      ),
      QuestItem(
        id: 'q-$now-2',
        title: _pick([
          'Tập trung sâu $studyMins phút thực hiện nhiệm vụ trọng tâm: $topic',
          'Thực hành nghiêm túc $actionMins phút nâng cao kỹ năng: $topic',
        ]),
        subtitle: 'Loại bỏ hoàn toàn thông báo gây phân tâm, duy trì trạng thái dòng chảy',
        xp: 220,
        spiritStones: 26,
        difficulty: 'MEDIUM',
        icon: Icons.auto_awesome,
        iconColor: const Color(0xFFF59E0B),
      ),
      QuestItem(
        id: 'q-$now-3',
        title: _pick([
          'Bứt phá giới hạn: Hoàn tất 1 cột mốc quan trọng của $topic',
          'Thử thách cực hạn: Tổng kết ngày và tối ưu hóa quy trình rèn luyện $topic',
        ]),
        subtitle: 'Đánh giá kết quả bằng số liệu cụ thể, không chấp nhận sự trì hoãn',
        xp: 410,
        spiritStones: 50,
        difficulty: 'HARD',
        icon: Icons.military_tech_rounded,
        iconColor: const Color(0xFFFBBF24),
      ),
    ];
  }
}
