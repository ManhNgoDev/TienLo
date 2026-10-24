import 'package:flutter/material.dart';

class QuestItem {
  final String id;
  final String title;
  final String subtitle;
  final int xp;
  final int spiritStones;
  final String difficulty; // 'EASY', 'MEDIUM', 'HARD', 'BREAKTHROUGH'
  final IconData icon;
  final Color iconColor;
  bool isCompleted;
  bool isXpClaimed;

  QuestItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xp,
    this.spiritStones = 15,
    this.difficulty = 'MEDIUM',
    required this.icon,
    required this.iconColor,
    this.isCompleted = false,
    this.isXpClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'xp': xp,
    'spiritStones': spiritStones,
    'difficulty': difficulty,
    'iconCode': icon.codePoint,
    'iconColor': iconColor.toARGB32(),
    'isCompleted': isCompleted,
    'isXpClaimed': isXpClaimed,
  };

  static IconData iconFromCode(int? code) {
    if (code == null) return Icons.fitness_center_rounded;
    if (code == Icons.restaurant_rounded.codePoint) return Icons.restaurant_rounded;
    if (code == Icons.fitness_center_rounded.codePoint) return Icons.fitness_center_rounded;
    if (code == Icons.bedtime_rounded.codePoint) return Icons.bedtime_rounded;
    if (code == Icons.water_drop_outlined.codePoint) return Icons.water_drop_outlined;
    if (code == Icons.directions_walk_rounded.codePoint) return Icons.directions_walk_rounded;
    if (code == Icons.auto_awesome.codePoint) return Icons.auto_awesome;
    if (code == Icons.military_tech_rounded.codePoint) return Icons.military_tech_rounded;
    if (code == Icons.track_changes_rounded.codePoint) return Icons.track_changes_rounded;
    if (code == Icons.menu_book_rounded.codePoint) return Icons.menu_book_rounded;
    if (code == Icons.code_rounded.codePoint) return Icons.code_rounded;
    if (code == Icons.self_improvement_rounded.codePoint) return Icons.self_improvement_rounded;
    if (code == Icons.bolt_rounded.codePoint) return Icons.bolt_rounded;
    if (code == Icons.emoji_events_rounded.codePoint) return Icons.emoji_events_rounded;
    if (code == Icons.favorite_rounded.codePoint) return Icons.favorite_rounded;
    if (code == Icons.timer_rounded.codePoint) return Icons.timer_rounded;
    if (code == Icons.local_fire_department_rounded.codePoint) return Icons.local_fire_department_rounded;
    if (code == Icons.diamond_outlined.codePoint) return Icons.diamond_outlined;
    return Icons.fitness_center_rounded;
  }

  factory QuestItem.fromJson(Map<String, dynamic> json) => QuestItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    xp: (json['xp'] as num?)?.toInt() ?? 100,
    spiritStones: (json['spiritStones'] as num?)?.toInt() ?? 15,
    difficulty: json['difficulty']?.toString() ?? 'MEDIUM',
    icon: iconFromCode(json['iconCode'] as int?),
    iconColor: json['iconColor'] != null
        ? Color(json['iconColor'] as int)
        : const Color(0xFFF2C465),
    isCompleted: json['isCompleted'] == true,
    isXpClaimed: json['isXpClaimed'] == true,
  );
}

Map<String, dynamic> getQuestDifficultyInfo(String diff) {
  final upper = diff.toUpperCase().trim();
  if (upper == 'EASY' || upper.contains('DỄ') || upper.contains('LUYỆN THỂ')) {
    return {
      'label': 'DỄ',
      'color': const Color(0xFF10B981),
      'bgColor': const Color(0xFF10B981).withValues(alpha: 0.15),
    };
  } else if (upper == 'HARD' || upper.contains('KHÓ') || upper.contains('NGƯNG ĐAN')) {
    return {
      'label': 'KHÓ',
      'color': const Color(0xFFF97316),
      'bgColor': const Color(0xFFF97316).withValues(alpha: 0.15),
    };
  } else if (upper == 'BREAKTHROUGH' || upper.contains('ĐỘT PHÁ') || upper.contains('THIÊN KIẾP')) {
    return {
      'label': 'ĐỘT PHÁ',
      'color': const Color(0xFFA855F7),
      'bgColor': const Color(0xFFA855F7).withValues(alpha: 0.18),
    };
  } else {
    return {
      'label': 'VỪA',
      'color': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFF59E0B).withValues(alpha: 0.15),
    };
  }
}
