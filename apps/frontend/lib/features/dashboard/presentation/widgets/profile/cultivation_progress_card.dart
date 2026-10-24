import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CultivationProgressCard extends StatelessWidget {
  final String nextTitle;
  final int currentExp;
  final int maxExp;
  final int expNeeded;
  final int progressPercent;
  final VoidCallback? onTap;

  const CultivationProgressCard({
    super.key,
    required this.nextTitle,
    required this.currentExp,
    required this.maxExp,
    required this.expNeeded,
    required this.progressPercent,
    this.onTap,
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
            Row(
              children: [
                Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    color: Color(0xFFF2C465),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE8B95E), size: 11),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Card
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Linh Quang Icon Box
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F1E2E),
                            border: Border.all(
                              color: const Color(0xFFF2C465),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF2C465).withValues(alpha: 0.30),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.auto_awesome, color: Color(0xFFF2C465), size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Text column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'MỤC TIÊU ĐỘT PHÁ',
                                    style: TextStyle(
                                      color: Color(0xFF8BA5BA),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'Còn thiếu ${_formatNumber(expNeeded)} Linh Lực',
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
                                  color: const Color(0xFFFFF6DF),
                                  fontSize: 16.5,
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
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF07121D),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF1E3246),
                          width: 1.0,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = (constraints.maxWidth * percent).clamp(0.0, constraints.maxWidth);
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: barWidth,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD97706),
                                        Color(0xFFF59E0B),
                                        Color(0xFFFDE68A),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.65),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bottom Linh Lực numbers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatNumber(currentExp)} Linh Lực',
                          style: const TextStyle(
                            color: Color(0xFFBAC7D5),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Mục tiêu: ${_formatNumber(maxExp)} Linh Lực',
                          style: const TextStyle(
                            color: Color(0xFF8BA5BA),
                            fontSize: 11.5,
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
        ),
      ],
    );
  }
}
