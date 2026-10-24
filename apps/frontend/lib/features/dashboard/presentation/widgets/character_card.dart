import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/cultivation_repository.dart';
import 'custom_painters.dart';

class CharacterCard extends StatelessWidget {
  final CultivationProfileModel? profile;
  final int currentExp;
  final int maxExp;
  final int streakDays;
  final int spiritStones;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.profile,
    required this.currentExp,
    required this.maxExp,
    required this.streakDays,
    required this.spiritStones,
    required this.onTap,
  });

  String _formatExp(int value) {
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
    final expPercent = (currentExp / maxExp).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
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
            padding: const EdgeInsets.all(3.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C2034).withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Lotus Badge
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF081524).withValues(alpha: 0.50),
                      border: Border.all(
                        color: const Color(0xFFC59A44).withValues(alpha: 0.70),
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: CustomPaint(
                        size: Size(26, 26),
                        painter: LotusFlowerPainter(
                          color: Color(0xFFF2C465),
                          strokeWidth: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Character Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'NHÂN VẬT CỦA BẠN',
                          style: TextStyle(
                            color: Color(0xFF70BFE6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile != null
                              ? (profile!.realmIndex == 0
                                  ? 'Phàm Nhân'
                                  : '${profile!.realmName} • Tầng ${profile!.subRealm}')
                              : 'Phàm Nhân',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFFFF6DF),
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress Bar
                        Container(
                          width: double.infinity,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1624),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: const Color(0xFF1E2F40),
                              width: 0.6,
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final barWidth = (constraints.maxWidth * expPercent).clamp(0.0, constraints.maxWidth);
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: Container(
                                      width: barWidth,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE5B869), Color(0xFFF6CE70)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF2C465).withValues(alpha: 0.5),
                                            blurRadius: 6,
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
                        const SizedBox(height: 6),
                        Text(
                          profile != null
                              ? (profile!.realmIndex == 0
                                  ? '${_formatExp(currentExp)} / ${_formatExp(maxExp)} Linh Lực đột phá Tiên Lộ'
                                  : (profile!.subRealm >= 10
                                      ? '${_formatExp(currentExp)} / ${_formatExp(maxExp)} Linh Lực đột phá Cảnh Giới'
                                      : '${_formatExp(currentExp)} / ${_formatExp(maxExp)} Linh Lực đột phá Tầng ${profile!.subRealm + 1}'))
                              : '${_formatExp(currentExp)} / ${_formatExp(maxExp)} Linh Lực để đột phá',
                          style: const TextStyle(
                            color: Color(0xFF8BA5BA),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 3. Streak Days (Flame + Days)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$streakDays',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'ngày',
                        style: TextStyle(
                          color: Color(0xFF8BA5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (spiritStones > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond_outlined, color: Color(0xFF38BDF8), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '$spiritStones',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
