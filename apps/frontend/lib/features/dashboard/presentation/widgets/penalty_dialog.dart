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
  final int? remainingExp;
  final int? maxExp;
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
    this.remainingExp,
    this.maxExp,
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
    int? remainingExp,
    int? maxExp,
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
        remainingExp: remainingExp,
        maxExp: maxExp,
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
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF140508).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.85),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Lôi Kiếp Thiên Phạt
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.65),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Title Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '⚡ THIÊN ĐẠO TRỪNG PHẠT ⚡',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa Hoàn Thành Hết Nhiệm Vụ',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF1F2),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Thiên Quy Bất Dịch • Tu Vi Tổn Hao',
                style: TextStyle(
                  color: Color(0xFFFDA4AF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Thông điệp cảnh báo
              Text(
                'Hôm qua đạo hữu chưa hoàn thành $uncompletedCount nhiệm vụ tu luyện! Đạo tâm bất định, Thiên Đạo giáng hạ lôi kiếp trừng phạt.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Chi tiết tổn thất Linh Lực
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF24070B).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFF87171), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Bị trừ Linh Lực:',
                          style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '-${_formatNumber(penaltyExp)} Linh Lực',
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 5. CẢNH BÁO TỤT TẦNG / TỤT CẢNH GIỚI (TRỌNG TÂM)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (demotedLevel || demotedRealm)
                      ? const Color(0xFF33060A)
                      : const Color(0xFF19202E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (demotedLevel || demotedRealm)
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (demotedLevel || demotedRealm)
                              ? Icons.trending_down_rounded
                              : Icons.shield_outlined,
                          color: (demotedLevel || demotedRealm)
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF38BDF8),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          demotedRealm
                              ? 'CẢNH GIỚI BỊ THOÁI HÓA (RỚT CẢNH GIỚI)!'
                              : (demotedLevel
                                  ? 'BỊ TỤT TẦNG TU LUYỆN!'
                                  : 'TRẠNG THÁI CẢNH GIỚI HIỆN TẠI'),
                          style: TextStyle(
                            color: (demotedLevel || demotedRealm)
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF38BDF8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (demotedRealm || demotedLevel) ...[
                      // Hiển thị biến động: Trước ➔ Tụt xuống
                      Text(
                        'Trước: $previousRealmName - Tầng $previousSubRealm',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF450A0A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '⬇️ Tụt xuống: ',
                              style: TextStyle(color: Color(0xFFFDE68A), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$currentRealmName - Tầng $currentSubRealm',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Không bị tụt tầng
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Giữ vững: $currentRealmName - Tầng $currentSubRealm',
                          style: const TextStyle(
                            color: Color(0xFFBAE6FD),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Linh lực đã bị trừ nhưng may mắn chưa rơi tầng tu luyện.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],

                    if (remainingExp != null && maxExp != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Linh lực còn lại: ${_formatNumber(remainingExp!)} / ${_formatNumber(maxExp!)}',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 6. Ghi chú bảo hiểm Luyện Khí Tầng 1
              if (isLuyenKhiProtected) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1929),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thiên Đạo bảo hộ: Dừng tại Luyện Khí Tầng 1 (0 Linh Lực), tu sĩ không bị tụt xuống Phàm Nhân!',
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
                const SizedBox(height: 10),
              ],

              // 7. Chuỗi ngày kiên trì
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1012),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chuỗi ngày kiên trì:',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    Text(
                      'Bị gián đoạn (0 ngày)',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 8. Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tạ Tội Thiên Đạo & Khắc Phục',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
