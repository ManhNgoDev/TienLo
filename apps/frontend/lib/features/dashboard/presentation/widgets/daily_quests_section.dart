import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/quest_item.dart';
import 'quest_card.dart';

class DailyQuestsSection extends StatelessWidget {
  final List<QuestItem> quests;
  final int completedCount;
  final ValueChanged<QuestItem> onToggleQuest;

  const DailyQuestsSection({
    super.key,
    required this.quests,
    required this.completedCount,
    required this.onToggleQuest,
  });

  Widget _buildEmptyQuestsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.65),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F1B2B),
                  border: Border.all(
                    color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFF2C465),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chưa có nhiệm vụ tu luyện',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF6DF),
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy nhập mục tiêu vào "Tạo chiến dịch mới" phía trên để Thiên Đạo AI diễn toán và ban bố nhiệm vụ tu chân cho đạo hữu!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAILY QUESTS',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFF2D1),
                      Color(0xFFF6CE70),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Ba hành động tạo khác biệt',
                    style: GoogleFonts.dancingScript(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
            if (quests.isNotEmpty)
              Text(
                '$completedCount/${quests.length} đã hoàn\nthành',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (quests.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFFF87171),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chưa hoàn thành hết nhiệm vụ trong ngày sẽ bị Thiên Đạo phạt trừ linh lực và tụt cảnh giới/tầng vào ngày hôm sau!',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // List of Quests or Empty State
        if (quests.isEmpty)
          _buildEmptyQuestsCard()
        else
          ...quests.map((quest) => QuestCard(
                quest: quest,
                onToggle: onToggleQuest,
              )),
      ],
    );
  }
}
