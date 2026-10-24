import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PenaltyDialog extends StatelessWidget {
  final int uncompletedCount;
  final int penaltyExp;
  final String reason;
  final bool demotedLevel;
  final bool demotedRealm;
  final String previousRealmName;
  final int previousSubRealm;
  final String currentRealmName;
  final int currentSubRealm;
  final VoidCallback onDismiss;

  const PenaltyDialog({
    super.key,
    required this.uncompletedCount,
    required this.penaltyExp,
    required this.reason,
    required this.demotedLevel,
    required this.demotedRealm,
    required this.previousRealmName,
    required this.previousSubRealm,
    required this.currentRealmName,
    required this.currentSubRealm,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int uncompletedCount,
    required int penaltyExp,
    required String reason,
    required bool demotedLevel,
    required bool demotedRealm,
    required String previousRealmName,
    required int previousSubRealm,
    required String currentRealmName,
    required int currentSubRealm,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PenaltyDialog(
        uncompletedCount: uncompletedCount,
        penaltyExp: penaltyExp,
        reason: reason,
        demotedLevel: demotedLevel,
        demotedRealm: demotedRealm,
        previousRealmName: previousRealmName,
        previousSubRealm: previousSubRealm,
        currentRealmName: currentRealmName,
        currentSubRealm: currentSubRealm,
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss();
        },
      ),
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
    final bool isLuyenKhiProtected =
        (currentRealmName == 'Luyện Khí' && currentSubRealm == 1);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16080C).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Lôi Kiếp Thiên Phạt
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title Header
              const Text(
                '⚡ THIÊN ĐẠO TRỪNG PHẠT ⚡',
                style: TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tâm Ma Xâm Lấn',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF1F2),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Thông điệp
              Text(
                'Hôm qua đạo hữu chưa hoàn thành $uncompletedCount nhiệm vụ tu luyện! Thiên quy bất dịch, tu vi bị hao tổn nghiêm trọng.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFDA4AF),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // 4. Chi tiết hình phạt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF260A10).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổn thất linh lực:',
                          style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                        ),
                        Text(
                          '-${_formatNumber(penaltyExp)} Linh Lực',
                          style: const TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chuỗi ngày kiên trì:',
                          style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
                        ),
                        Text(
                          'Bị gián đoạn (0 ngày)',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Cảnh báo tụt tầng / tụt cảnh giới
              if (demotedLevel || demotedRealm) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B070B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_down_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            demotedRealm ? 'CẢNH GIỚI BỊ THOÁI HÓA!' : 'BỊ TỤT TẦNG TU LUYỆN!',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$previousRealmName Tầng $previousSubRealm  ➔  $currentRealmName Tầng $currentSubRealm',
                        style: const TextStyle(
                          color: Color(0xFFFDE8E8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 6. Ghi chú bảo hiểm Luyện Khí Tầng 1
              if (isLuyenKhiProtected) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132235),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thiên Đạo bảo hộ: Đạo hữu đã bước vào Luyện Khí nên không bị tụt xuống Phàm Nhân!',
                          style: TextStyle(
                            color: Color(0xFFBAE6FD),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 7. Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                    ),
                  ),
                  child: const Text(
                    'Tạ Tội Thiên Đạo & Khắc Phục',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
