import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedAchievementsCard extends StatelessWidget {
  final List<Map<String, dynamic>> featuredAchievements;
  final List<Map<String, dynamic>> allAchievements;

  const FeaturedAchievementsCard({
    super.key,
    required this.featuredAchievements,
    required this.allAchievements,
  });

  IconData _getIconData(String? icon) {
    switch (icon) {
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'diamond':
        return Icons.diamond_outlined;
      case 'medal':
        return Icons.military_tech_rounded;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getIconColor(String? icon) {
    switch (icon) {
      case 'flame':
        return const Color(0xFFF97316);
      case 'trophy':
        return const Color(0xFFF59E0B);
      case 'bolt':
        return const Color(0xFF2DD4BF);
      case 'diamond':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFFE5B869);
    }
  }

  void _showAllAchievementsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF091726).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: const Color(0xFFC59A44), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A758D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bảng Thành Tựu Tu Tiên',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFFFF6DF),
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8BA5BA)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: allAchievements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ach = allAchievements[index];
                      final isUnlocked = ach['isUnlocked'] == true;
                      final icon = ach['icon'] as String?;
                      final color = _getIconColor(icon);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? const Color(0xFF132235)
                              : const Color(0xFF0C1929).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnlocked
                                ? color.withValues(alpha: 0.5)
                                : const Color(0xFF1E2F40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: isUnlocked ? 0.2 : 0.08),
                                border: Border.all(
                                  color: color.withValues(alpha: isUnlocked ? 0.8 : 0.3),
                                ),
                              ),
                              child: Icon(
                                _getIconData(icon),
                                color: isUnlocked ? color : const Color(0xFF5A758D),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ach['title'] ?? '',
                                    style: TextStyle(
                                      color: isUnlocked ? Colors.white : const Color(0xFF8BA5BA),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ach['subtitle'] ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF8BA5BA),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                                    : const Color(0xFF1E2F40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUnlocked ? 'Đạt được' : 'Chưa mở',
                                style: TextStyle(
                                  color: isUnlocked ? const Color(0xFF2DD4BF) : const Color(0xFF5A758D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementItem(Map<String, dynamic> item) {
    final icon = item['icon'] as String?;
    final title = item['title']?.toString() ?? '';
    final subtitle = item['subtitle']?.toString() ?? '';
    final color = _getIconColor(icon);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF091726).withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(
                      color: color.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(_getIconData(icon), color: color, size: 22),
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),

                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8BA5BA),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = featuredAchievements.isNotEmpty
        ? featuredAchievements.take(3).toList()
        : [
            {'icon': 'flame', 'title': 'Bền bỉ', 'subtitle': '7 ngày liên tiếp'},
            {'icon': 'trophy', 'title': 'Khởi đầu', 'subtitle': '50 nhiệm vụ'},
            {'icon': 'bolt', 'title': 'Tập trung', 'subtitle': '500 phút'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'THÀNH TỰU NỔI BẬT',
              style: TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            GestureDetector(
              onTap: () => _showAllAchievementsSheet(context),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Color(0xFFE8B95E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row of 3 Achievement items
        Row(
          children: [
            _buildAchievementItem(list[0]),
            const SizedBox(width: 10),
            _buildAchievementItem(list[1]),
            const SizedBox(width: 10),
            _buildAchievementItem(list[2]),
          ],
        ),
      ],
    );
  }
}
