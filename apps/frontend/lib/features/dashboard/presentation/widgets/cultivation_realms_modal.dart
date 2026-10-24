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

  int _calculateSubRealmExp(int realmIndex, int tier) {
    if (realmIndex == 0) return 1000;
    if (realmIndex >= 9) return 9999999;

    const baseExps = {
      1: 1000,   // Luyện Khí
      2: 2500,   // Kết Đan
      3: 5000,   // Nguyên Anh
      4: 10000,  // Hóa Thần
      5: 20000,  // Luyện Hư
      6: 40000,  // Đại Thừa
      7: 80000,  // Hợp Thể
      8: 150000, // Độ Kiếp
    };

    final base = baseExps[realmIndex] ?? 1000;
    final targetTier = tier.clamp(1, 10);
    if (targetTier <= 1) return base;

    double exp = base.toDouble();
    for (int t = 2; t <= targetTier; t++) {
      final factor = (1.0 + 0.1 + (t - 2) * 0.1).clamp(1.0, 5.0);
      exp = ((exp * factor) / 50).round() * 50.0;
    }
    return exp.toInt();
  }

  void _showRealmDetailModal(BuildContext context, CultivationRealmModel realm) {
    if (realm.subRealms <= 1) return; // Phàm Nhân & Phi Tiên không cần mở chi tiết 10 tầng

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int totalExp = 0;
        final List<Map<String, dynamic>> tiersData = [];
        for (int t = 1; t <= 10; t++) {
          final exp = _calculateSubRealmExp(realm.index, t);
          totalExp += exp;
          final factor = (1.0 + 0.1 + (t - 2) * 0.1).clamp(1.0, 5.0);
          tiersData.add({
            'tier': t,
            'exp': exp,
            'factor': t == 1 ? 'Khởi đầu' : 'x${factor.toStringAsFixed(1)} (+${((factor - 1) * 100).toInt()}%)',
          });
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF091726).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: const Color(0xFFC59A44), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A758D),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHI TIẾT 10 TẦNG ĐỘT PHÁ',
                          style: const TextStyle(
                            color: Color(0xFFC59A44),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          realm.name,
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFFFF6DF),
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8BA5BA)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132235),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC59A44).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quy tắc: Tăng từ x0.1 (x1.1) ↗ x1.9',
                        style: TextStyle(color: Color(0xFFBAC7D5), fontSize: 11),
                      ),
                      Text(
                        'Tổng: ${_formatNumber(totalExp)} EXP',
                        style: const TextStyle(
                          color: Color(0xFFF2C465),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: tiersData.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final item = tiersData[idx];
                      final isCurrentTier =
                          (profile.realmIndex == realm.index && profile.subRealm == item['tier']);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrentTier
                              ? const Color(0xFF1A334E)
                              : const Color(0xFF0C1929).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentTier
                                ? const Color(0xFFF2C465)
                                : const Color(0xFF1E2F40),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrentTier
                                    ? const Color(0xFFF2C465)
                                    : const Color(0xFF1E2F40),
                              ),
                              child: Center(
                                child: Text(
                                  '${item['tier']}',
                                  style: TextStyle(
                                    color: isCurrentTier ? Colors.black : const Color(0xFFBAC7D5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['tier'] == 10
                                    ? 'Tầng 10 (Đột phá Cảnh Giới)'
                                    : 'Tầng ${item['tier']} ➔ Tầng ${item['tier'] + 1}',
                                style: TextStyle(
                                  color: isCurrentTier ? Colors.white : const Color(0xFFBAC7D5),
                                  fontWeight: isCurrentTier ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatNumber(item['exp'])} EXP',
                                  style: TextStyle(
                                    color: isCurrentTier
                                        ? const Color(0xFFF2C465)
                                        : const Color(0xFF38BDF8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${item['factor']}',
                                  style: const TextStyle(
                                    color: Color(0xFF5A758D),
                                    fontSize: 9.5,
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
        );
      },
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

                    return GestureDetector(
                      onTap: () => _showRealmDetailModal(context, realm),
                      child: Container(
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      realm.subRealms > 1
                                          ? '${realm.subRealms} tầng cần đột phá'
                                          : (realm.index == 0 ? 'Phàm Thai' : 'Cực Cảnh'),
                                      style: const TextStyle(
                                        color: Color(0xFF5A758D),
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (realm.subRealms > 1) ...[
                                      const SizedBox(width: 3),
                                      const Icon(Icons.info_outline, color: Color(0xFF5A758D), size: 11),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
