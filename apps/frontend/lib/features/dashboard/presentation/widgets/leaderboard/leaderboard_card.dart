import 'package:flutter/material.dart';
import '../../../domain/leaderboard_item.dart';
import 'leaderboard_avatar.dart';
import 'leaderboard_constants.dart';

class LeaderboardCard extends StatelessWidget {
  final LeaderboardItem item;

  const LeaderboardCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = item.isCurrentUser;
    final realmColor = getRealmColor(item.realmIndex);

    Color rankBadgeBg;
    Color rankBadgeText;
    if (item.rank == 1) {
      rankBadgeBg = const Color(0xFFFFD700);
      rankBadgeText = const Color(0xFF1E1B4B);
    } else if (item.rank == 2) {
      rankBadgeBg = const Color(0xFFCBD5E1);
      rankBadgeText = const Color(0xFF0F172A);
    } else if (item.rank == 3) {
      rankBadgeBg = const Color(0xFFCD7F32);
      rankBadgeText = const Color(0xFFFFFFFF);
    } else {
      rankBadgeBg = const Color(0xFF1E293B);
      rankBadgeText = const Color(0xFF94A3B8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1B2838).withValues(alpha: 0.90)
            : const Color(0xFF0E1A29).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe
              ? const Color(0xFFF3C766)
              : (item.rank <= 3
                  ? rankBadgeBg.withValues(alpha: 0.45)
                  : const Color(0xFF24364D)),
          width: isMe ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0xFFF3C766).withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.20),
            blurRadius: isMe ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankBadgeBg,
              boxShadow: item.rank <= 3
                  ? [
                      BoxShadow(
                        color: rankBadgeBg.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.rank}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: rankBadgeText,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. Avatar
          LeaderboardAvatar(item: item, size: 44),
          const SizedBox(width: 12),

          // 3. User Details: Name & Cảnh Giới
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isMe ? const Color(0xFFFDE68A) : Colors.white,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3C766),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BẠN',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Cảnh Giới Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: realmColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: realmColor.withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 11, color: realmColor),
                          const SizedBox(width: 3),
                          Text(
                            item.realmText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: realmColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 4. Metrics: Chuỗi & Số nhiệm vụ hoàn thành
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFB923C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFB923C).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Color(0xFFFB923C), size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${item.streakDays} ngày',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDBA74),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.task_alt_rounded,
                        color: Color(0xFF38BDF8), size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${item.completedQuestsCount} xong',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
