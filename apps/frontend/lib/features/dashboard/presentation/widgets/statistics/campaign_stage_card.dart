import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignStageCard extends StatelessWidget {
  final String title;
  final double progress;
  final bool hasActiveCampaign;

  const CampaignStageCard({
    super.key,
    required this.title,
    required this.progress,
    this.hasActiveCampaign = true,
  });

  @override
  Widget build(BuildContext context) {
    final int stageIndex = hasActiveCampaign ? (progress * 4).floor().clamp(0, 3) : 0;
    const stages = ['Khởi động', 'Nền tảng', 'Đột phá', 'Duy trì'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MAIN QUEST',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chiến Dịch Đang Chơi',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                hasActiveCampaign ? 'Giai đoạn hiện tại' : 'Chưa mở phiên',
                style: const TextStyle(
                  color: Color(0xFFF2C465),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF081626).withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC59A44).withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.fitness_center_rounded, color: Color(0xFFF2C465), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasActiveCampaign ? title : 'Chưa có chiến dịch nào',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hasActiveCampaign
                                  ? 'Stage ${stageIndex + 1}/4 • ${stages[stageIndex]}'
                                  : 'Stage 0/4 • Chưa bắt đầu',
                              style: const TextStyle(
                                color: Color(0xFF8BA5BA),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(hasActiveCampaign ? (progress * 100).toInt() : 0)}%',
                        style: const TextStyle(
                          color: Color(0xFFF2C465),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1624),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              width: constraints.maxWidth *
                                  (hasActiveCampaign ? progress.clamp(0.0, 1.0) : 0.0),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stepper 4 Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(stages.length, (idx) {
                      final isCurrent = hasActiveCampaign && idx == stageIndex;
                      final isPassed = hasActiveCampaign && idx < stageIndex;
                      return Text(
                        stages[idx],
                        style: TextStyle(
                          color: isCurrent
                              ? const Color(0xFFF2C465)
                              : isPassed
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w400,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
