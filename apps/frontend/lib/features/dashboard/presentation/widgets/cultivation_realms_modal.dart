import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/cultivation_repository.dart';

class CultivationRealmsModal extends StatelessWidget {
  final CultivationProfileModel profile;

  const CultivationRealmsModal({super.key, required this.profile});

  static void show(BuildContext context, CultivationProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CultivationRealmsModal(profile: profile),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF07121E).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFFC59A44), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // 1. Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A758D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Modal Header (responsive with Expanded to avoid overflow)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BẢNG HỆ THỐNG TU TIÊN',
                            style: TextStyle(
                              color: Color(0xFFC59A44),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '10 Cảnh Giới • Phàm Nhân Đến Phi Tiên',
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
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8BA5BA)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. User Current Status Bar (compact & responsive badges)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1726),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC59A44).withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Realm Badge
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2C465).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF2C465), width: 1),
                              ),
                              child: Text(
                                profile.realmIndex == 0
                                    ? 'Phàm Nhân • Phàm Thai'
                                    : '${profile.realmName} • Tầng ${profile.subRealm}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF2C465),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nguyên Thạch Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.spiritStones}',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // EXP Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2C465).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF2C465).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFF2C465), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatNumber(profile.currentExp)}/${_formatNumber(profile.maxExp)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Realms List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: profile.allRealms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final realm = profile.allRealms[index];
                    final isCurrent = realm.index == profile.realmIndex;
                    final isPassed = realm.index < profile.realmIndex;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF102032)
                            : const Color(0xFF08121D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFFC59A44)
                              : isPassed
                                  ? const Color(0xFF3B5771).withValues(alpha: 0.6)
                                  : const Color(0xFF1E2F40),
                          width: isCurrent ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Index / Status Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? const Color(0xFFF2C465).withValues(alpha: 0.2)
                                  : const Color(0xFF0C1826),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFFF2C465)
                                    : const Color(0xFF3B5771),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: isPassed
                                  ? const Icon(Icons.check_rounded, color: Color(0xFF38BDF8), size: 18)
                                  : isCurrent
                                      ? const Icon(Icons.auto_awesome, color: Color(0xFFF2C465), size: 18)
                                      : Text(
                                          '${realm.index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF5A758D),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Realm Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      realm.name,
                                      style: GoogleFonts.playfairDisplay(
                                        color: isCurrent
                                            ? const Color(0xFFFFF6DF)
                                            : isPassed
                                                ? Colors.white70
                                                : const Color(0xFF6B8296),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2C465),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'HIỆN TẠI',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  realm.title,
                                  style: TextStyle(
                                    color: isCurrent ? const Color(0xFF8BA5BA) : const Color(0xFF5A758D),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // EXP requirement (Tầng 1-10 tăng lũy tiến từ x0.1 đến x1.9)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                realm.expPerSubRealm > 0
                                    ? (realm.index == 0
                                        ? '${_formatNumber(realm.expPerSubRealm)} EXP đột phá'
                                        : (realm.minExp > 0 && realm.maxExp > realm.minExp
                                            ? '${_formatNumber(realm.minExp)} - ${_formatNumber(realm.maxExp)} EXP'
                                            : '${_formatNumber(realm.expPerSubRealm)} EXP/tầng'))
                                    : 'Cực cảnh',
                                style: TextStyle(
                                  color: isCurrent ? const Color(0xFFF2C465) : const Color(0xFF7E98AE),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                realm.subRealms > 1
                                    ? '${realm.subRealms} tầng (x0.1 ↗ x1.9)'
                                    : (realm.index == 0 ? 'Phàm Thai' : 'Cực Cảnh'),
                                style: const TextStyle(
                                  color: Color(0xFF5A758D),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
