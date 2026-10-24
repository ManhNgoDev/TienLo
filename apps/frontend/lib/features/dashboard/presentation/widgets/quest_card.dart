import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/quest_item.dart';
import 'custom_painters.dart';

class QuestCard extends StatelessWidget {
  final QuestItem quest;
  final ValueChanged<QuestItem> onToggle;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onToggle,
  });

  Widget _buildQuestIcon(QuestItem quest) {
    if (quest.id == '1') {
      return CustomPaint(
        size: const Size(26, 26),
        painter: BarbellIconPainter(color: quest.iconColor),
      );
    } else if (quest.id == '2') {
      return Icon(
        Icons.water_drop_outlined,
        color: quest.iconColor,
        size: 24,
      );
    } else if (quest.id == '3') {
      return CustomPaint(
        size: const Size(24, 24),
        painter: FootprintIconPainter(color: quest.iconColor),
      );
    }
    return Icon(quest.icon, color: quest.iconColor, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasStrikethrough = quest.isXpClaimed || quest.isCompleted;
    final diffInfo = getQuestDifficultyInfo(quest.difficulty);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: quest.isCompleted
                ? const Color(0xFF071828).withValues(alpha: 0.30)
                : const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: quest.isCompleted
                  ? const Color(0xFFC59A44).withValues(alpha: 0.35)
                  : const Color(0xFFC59A44).withValues(alpha: 0.65),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left: Icon Box
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF081626).withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: quest.iconColor.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: _buildQuestIcon(quest),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Middle: Difficulty Badge + Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Difficulty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: diffInfo['bgColor'],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (diffInfo['color'] as Color).withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        diffInfo['label'],
                        style: TextStyle(
                          color: diffInfo['color'],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      quest.title,
                      style: TextStyle(
                        color: hasStrikethrough ? const Color(0xFF8BA5BA) : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        decoration: hasStrikethrough ? TextDecoration.lineThrough : null,
                        decorationColor: const Color(0xFF8BA5BA),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Subtitle
                    Text(
                      quest.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7E98AE),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 3. Right: Rewards (EXP + Spirit Stones) & Checkbox
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // EXP Reward
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFF2C465), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.xp} Linh Lực',
                        style: TextStyle(
                          color: const Color(0xFFF2C465),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: hasStrikethrough
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: const Color(0xFFF2C465),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Spirit Stones Reward (Nguyên Thạch)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        '+${quest.spiritStones} Nguyên Thạch',
                        style: TextStyle(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          decoration: hasStrikethrough
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Checkbox Circle
                  GestureDetector(
                    onTap: quest.isCompleted ? null : () => onToggle(quest),
                    child: MouseRegion(
                      cursor: quest.isCompleted
                          ? SystemMouseCursors.basic
                          : SystemMouseCursors.click,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: quest.isCompleted
                              ? const Color(0xFFF2C465).withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: quest.isCompleted
                                ? const Color(0xFFF2C465)
                                : const Color(0xFF5A758D),
                            width: 1.6,
                          ),
                        ),
                        child: quest.isCompleted
                            ? const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFFF2C465),
                                  size: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
