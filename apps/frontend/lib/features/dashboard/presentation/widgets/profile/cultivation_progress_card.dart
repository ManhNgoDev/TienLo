import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CultivationProgressCard extends StatelessWidget {
  final String nextTitle;
  final int currentExp;
  final int maxExp;
  final int expNeeded;
  final int progressPercent;

  const CultivationProgressCard({
    super.key,
    required this.nextTitle,
    required this.currentExp,
    required this.maxExp,
    required this.expNeeded,
    required this.progressPercent,
  });

  String _formatNumber(int value) {
    if (value >= 1000000000000000) {
      final v = value / 1000000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tr.Tỷ';
    }
    if (value >= 1000000000000) {
      final v = value / 1000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Ngàn Tỷ';
    }
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tỷ';
    }
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percent = (progressPercent / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TIẾN ĐỘ TU LUYỆN',
              style: TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              '$progressPercent%',
              style: const TextStyle(
                color: Color(0xFFE8B95E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Card
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Trophy Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF281C10).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'CẤP NHÂN VẬT TIẾP THEO',
                                  style: TextStyle(
                                    color: Color(0xFF8BA5BA),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  '${_formatNumber(expNeeded)} Linh Lực nữa',
                                  style: const TextStyle(
                                    color: Color(0xFFFB923C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              nextTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    height: 5,
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
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                                ),
                                borderRadius: BorderRadius.circular(2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom EXP numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatNumber(currentExp)} Linh Lực',
                        style: const TextStyle(
                          color: Color(0xFF8BA5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_formatNumber(maxExp)} Linh Lực',
                        style: const TextStyle(
                          color: Color(0xFF8BA5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
