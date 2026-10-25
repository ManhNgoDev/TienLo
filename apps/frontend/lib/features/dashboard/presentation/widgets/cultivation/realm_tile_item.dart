import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/cultivation_repository.dart';
import 'cultivation_calc_utils.dart';

class RealmTileItem extends StatelessWidget {
  final CultivationRealmModel realm;
  final CultivationProfileModel profile;
  final VoidCallback onTap;

  const RealmTileItem({
    super.key,
    required this.realm,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = realm.index == profile.realmIndex;
    final isPassed = realm.index < profile.realmIndex;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF102032) : const Color(0xFF08121D),
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
                  color: isCurrent ? const Color(0xFFF2C465) : const Color(0xFF3B5771),
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

            // EXP requirement
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  realm.expPerSubRealm > 0
                      ? (realm.index == 0
                          ? '${CultivationCalcUtils.formatNumber(realm.expPerSubRealm)} Linh Lực đột phá'
                          : (realm.minExp > 0 && realm.maxExp > realm.minExp
                              ? '${CultivationCalcUtils.formatNumber(realm.minExp)} - ${CultivationCalcUtils.formatNumber(realm.maxExp)} Linh Lực'
                              : '${CultivationCalcUtils.formatNumber(realm.expPerSubRealm)} Linh Lực/tầng'))
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
  }
}
