import 'package:flutter/material.dart';
import '../../../domain/leaderboard_item.dart';
import 'leaderboard_constants.dart';

class UserStandingCard extends StatelessWidget {
  final LeaderboardItem? currentUser;

  const UserStandingCard({
    super.key,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox.shrink();

    final item = currentUser!;
    final realmColor = getRealmColor(item.realmIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2D44), Color(0xFF132030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF3C766),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF3C766).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '#${item.rank}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VỊ THÍ THIÊN KIÊU CỦA BẠN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF3C766),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cảnh giới: ${item.realmText}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: realmColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🔥 ${item.streakDays} ngày',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDBA74),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '🎯 ${item.completedQuestsCount} nhiệm vụ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBAE6FD),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
