import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealLifeSkillTreeCard extends StatelessWidget {
  const RealLifeSkillTreeCard({super.key});

  Widget _buildSkillRow({
    required String label,
    required double percent,
    required String percentText,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBAC7D5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFF0C1624),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * percent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withValues(alpha: 0.4),
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
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 36,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'SKILL TREE',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Năng Lực Đời Thực',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Text(
              'Phân tích',
              style: TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildSkillRow(
                    label: 'Thể chất',
                    percent: 0.82,
                    percentText: '82%',
                    gradientColors: [const Color(0xFFEA580C), const Color(0xFFFB923C)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Trí thức',
                    percent: 0.64,
                    percentText: '64%',
                    gradientColors: [const Color(0xFFCA8A04), const Color(0xFFFDE047)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Tập trung',
                    percent: 0.71,
                    percentText: '71%',
                    gradientColors: [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Giao tiếp',
                    percent: 0.38,
                    percentText: '38%',
                    gradientColors: [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
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
