import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/cultivation_repository.dart';
import 'cultivation_calc_utils.dart';

class RealmSubTierDialog {
  static void show(
    BuildContext context, {
    required CultivationRealmModel realm,
    required CultivationProfileModel profile,
  }) {
    if (realm.subRealms <= 1) return; // Phàm Nhân & Phi Tiên không cần mở chi tiết 10 tầng

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int totalExp = 0;
        final List<Map<String, dynamic>> tiersData = [];
        for (int t = 1; t <= 10; t++) {
          final exp = CultivationCalcUtils.calculateSubRealmExp(realm.index, t);
          totalExp += exp;
          final factor = (1.0 + 0.10 + (t - 2) * 0.03).clamp(1.0, 1.35);
          tiersData.add({
            'tier': t,
            'exp': exp,
            'factor': t == 1 ? 'Khởi đầu' : 'x${factor.toStringAsFixed(2)} (+${((factor - 1) * 100).round()}%)',
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
                        const Text(
                          'CHI TIẾT 10 TẦNG ĐỘT PHÁ',
                          style: TextStyle(
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
                        'Quy tắc: Tăng từ x0.1 (x1.1) ↗ x1.35',
                        style: TextStyle(color: Color(0xFFBAC7D5), fontSize: 11),
                      ),
                      Text(
                        'Tổng: ${CultivationCalcUtils.formatNumber(totalExp)} Linh Lực',
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
                                  '${CultivationCalcUtils.formatNumber(item['exp'])} Linh Lực',
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
}
