import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainQuestProgressCard extends StatelessWidget {
  final String title;
  final int currentWeek;
  final int totalWeeks;
  final double progress;
  final int completedQuests;
  final int totalPlannedQuests;

  const MainQuestProgressCard({
    super.key,
    required this.title,
    required this.currentWeek,
    required this.totalWeeks,
    required this.progress,
    required this.completedQuests,
    required this.totalPlannedQuests,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
              Text(
                'MAIN QUEST • TUẦN $currentWeek/$totalWeeks',
                style: const TextStyle(
                  color: Color(0xFFE8B95E),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF6DF),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$completedQuests/$totalPlannedQuests nhiệm vụ chiến dịch đã hoàn thành',
                style: const TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),

              // Gold Progress Bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1624),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth * progress,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF2C465).withValues(alpha: 0.45),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
