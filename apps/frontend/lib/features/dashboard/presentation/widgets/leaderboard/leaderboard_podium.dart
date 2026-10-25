import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/leaderboard_item.dart';
import 'leaderboard_avatar.dart';
import 'leaderboard_constants.dart';

class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardItem> items;

  const LeaderboardPodium({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.length < 3) return const SizedBox.shrink();

    final top1 = items[0];
    final top2 = items[1];
    final top3 = items[2];

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF132235).withValues(alpha: 0.70),
            const Color(0xFF0C1624).withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5B869).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFF3C766), size: 18),
              const SizedBox(width: 6),
              Text(
                'BỤC VINH DANH THIÊN KIÊU',
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFF3C766),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Hạng 2 (Bạc - Trái)
              Expanded(
                child: _buildPodiumPillar(
                  item: top2,
                  height: 120,
                  rankColor: const Color(0xFFCBD5E1),
                  badgeIcon: Icons.military_tech_rounded,
                  crownEmoji: '🥈',
                ),
              ),
              const SizedBox(width: 8),

              // Hạng 1 (Vàng - Trung tâm cao nhất)
              Expanded(
                child: _buildPodiumPillar(
                  item: top1,
                  height: 148,
                  rankColor: const Color(0xFFFFD700),
                  badgeIcon: Icons.emoji_events_rounded,
                  crownEmoji: '👑',
                  isFirst: true,
                ),
              ),
              const SizedBox(width: 8),

              // Hạng 3 (Đồng - Phải)
              Expanded(
                child: _buildPodiumPillar(
                  item: top3,
                  height: 104,
                  rankColor: const Color(0xFFCD7F32),
                  badgeIcon: Icons.military_tech_rounded,
                  crownEmoji: '🥉',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required LeaderboardItem item,
    required double height,
    required Color rankColor,
    required IconData badgeIcon,
    required String crownEmoji,
    bool isFirst = false,
  }) {
    final realmColor = getRealmColor(item.realmIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          crownEmoji,
          style: TextStyle(fontSize: isFirst ? 22 : 18),
        ),
        const SizedBox(height: 2),

        LeaderboardAvatar(item: item, size: isFirst ? 56 : 46),
        const SizedBox(height: 6),

        Text(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isFirst ? 12.5 : 11,
            fontWeight: FontWeight.bold,
            color: isFirst ? const Color(0xFFFDE68A) : Colors.white,
          ),
        ),
        const SizedBox(height: 2),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: realmColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: realmColor.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Text(
            item.realmText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: realmColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                rankColor.withValues(alpha: isFirst ? 0.35 : 0.22),
                rankColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: rankColor.withValues(alpha: isFirst ? 0.8 : 0.4),
              width: isFirst ? 1.6 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${item.rank}',
                style: GoogleFonts.cinzel(
                  fontSize: isFirst ? 20 : 16,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFFB923C), size: 13),
                  const SizedBox(width: 2),
                  Text(
                    '${item.streakDays}d',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFB923C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF38BDF8), size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${item.completedQuestsCount} NV',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBAE6FD),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
