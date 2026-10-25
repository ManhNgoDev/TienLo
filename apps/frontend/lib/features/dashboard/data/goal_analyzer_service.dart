import 'package:flutter/material.dart';
import '../domain/quest_item.dart';

class GoalAnalyzerService {
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
    } else if (iconType == 'meditation' || iconType == 'study') {
      icon = Icons.auto_awesome;
      iconColor = const Color(0xFFA78BFA);
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

  static List<QuestItem> analyzeGoalAndCreateQuests(String goalText) {
    final lower = goalText.toLowerCase();
    final now = DateTime.now().millisecondsSinceEpoch;

    final isWeightGain = lower.contains('tăng cân') ||
        lower.contains('tang can') ||
        lower.contains('10 cân') ||
        lower.contains('10 can') ||
        lower.contains('tăng ký') ||
        lower.contains('tang ky');

    final isFitness = lower.contains('cơ bụng') ||
        lower.contains('co bung') ||
        lower.contains('giảm mỡ') ||
        lower.contains('giam mo') ||
        lower.contains('chạy') ||
        lower.contains('chay') ||
        lower.contains('5km');

    final isStudy = lower.contains('học') ||
        lower.contains('hoc') ||
        lower.contains('đọc') ||
        lower.contains('doc') ||
        lower.contains('code') ||
        lower.contains('tiếng anh');

    if (isWeightGain) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Ăn thêm 1 bữa phụ giàu Calo & Protein',
          subtitle: 'Bổ sung chuối, sữa chua, yến mạch hoặc hạt dinh dưỡng',
          xp: 100,
          spiritStones: 15,
          difficulty: 'EASY',
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFF10B981),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập tạ kích thích cơ bắp 30 phút',
          subtitle: 'Tập các bài Compound (Squat, Deadlift) gia tăng đồng hóa',
          xp: 220,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Uống sinh tố dinh dưỡng & ngủ đủ 8 tiếng',
          subtitle: 'Tối ưu quá trình hấp thu và tái tạo cơ bắp ban đêm',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    if (isFitness) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Uống đủ 2L nước lọc & hạn chế tối đa đường',
          subtitle: 'Thanh lọc cơ thể, hỗ trợ chuyển hóa mỡ thừa',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.water_drop_outlined,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập gập bụng & Plank 15 phút',
          subtitle: '3 hiệp Plank & Crunch kích hoạt cơ múi bụng',
          xp: 200,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFFF2C465),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Cardio hoặc chạy bộ 20 phút đốt mỡ',
          subtitle: 'Duy trì nhịp tim đốt calo thâm hụt sau buổi tập',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.directions_walk_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    if (isStudy) {
      return [
        QuestItem(
          id: 'q-$now-1',
          title: 'Đọc sách hoặc tài liệu 20 phút',
          subtitle: 'Khởi động tư duy mỗi sáng bằng tri thức mới',
          xp: 80,
          spiritStones: 10,
          difficulty: 'EASY',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF38BDF8),
        ),
        QuestItem(
          id: 'q-$now-2',
          title: 'Tập trung học sâu 45 phút Pomodoro',
          subtitle: 'Tuyệt đối không lướt mạng xã hội, tập trung cao độ',
          xp: 200,
          spiritStones: 25,
          difficulty: 'MEDIUM',
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFFF59E0B),
        ),
        QuestItem(
          id: 'q-$now-3',
          title: 'Thực hành làm bài tập hoặc viết code 30 phút',
          subtitle: 'Ứng dụng trực tiếp kiến thức vừa học vào thực tế',
          xp: 350,
          spiritStones: 40,
          difficulty: 'HARD',
          icon: Icons.code_rounded,
          iconColor: const Color(0xFFF97316),
        ),
      ];
    }

    return [
      QuestItem(
        id: 'q-$now-1',
        title: 'Uống đủ 2L nước lọc',
        subtitle: 'Bổ sung đều đặn trong ngày, thanh lọc cơ thể chuẩn bị thăng cấp',
        xp: 100,
        spiritStones: 15,
        difficulty: 'EASY',
        icon: Icons.water_drop_outlined,
        iconColor: const Color(0xFF38BDF8),
      ),
      QuestItem(
        id: 'q-$now-2',
        title: 'Chống đẩy 50 cái & Gập bụng 50 cái',
        subtitle: 'Chia làm 3-4 hiệp chạm ngực chuẩn form, nghỉ 60s. Không hoàn thành sẽ bị xử phạt!',
        xp: 220,
        spiritStones: 25,
        difficulty: 'MEDIUM',
        icon: Icons.fitness_center_rounded,
        iconColor: const Color(0xFFF2C465),
      ),
      QuestItem(
        id: 'q-$now-3',
        title: 'Chạy bộ 3km hoặc Squat 100 cái',
        subtitle: 'Duy trì nhịp chạy đều đặn không dừng lại, bứt phá giới hạn như Sung Jin-woo',
        xp: 400,
        spiritStones: 50,
        difficulty: 'HARD',
        icon: Icons.directions_walk_rounded,
        iconColor: const Color(0xFF34D399),
      ),
    ];
  }
}
