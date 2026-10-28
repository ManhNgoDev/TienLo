import 'dart:ui';
import 'package:flutter/material.dart';

class CreateCampaignCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isGeneratingAi;
  final bool isLocked;
  final String? lockedMessage;
  final VoidCallback onSubmitted;
  final VoidCallback? onLockedTap;

  const CreateCampaignCard({
    super.key,
    required this.controller,
    required this.isGeneratingAi,
    this.isLocked = false,
    this.lockedMessage,
    required this.onSubmitted,
    this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isLocked
        ? const Color(0xFFF59E0B).withValues(alpha: 0.50)
        : const Color(0xFFC59A44).withValues(alpha: 0.65);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isLocked
                ? const Color(0xFF13151D).withValues(alpha: 0.55)
                : const Color(0xFF091726).withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: borderColor,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Title + Subtitle
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFF241C10).withValues(alpha: 0.60)
                          : const Color(0xFF081524).withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLocked
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.60)
                            : const Color(0xFFC59A44).withValues(alpha: 0.70),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isLocked ? Icons.lock_clock_rounded : Icons.auto_awesome,
                        color: isLocked ? const Color(0xFFFBBF24) : const Color(0xFFF2C465),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isLocked ? 'Phiên tu luyện đang khóa' : 'Tạo chiến dịch mới',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (isLocked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309).withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'ĐANG RÈN LUYỆN',
                                  style: TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLocked
                              ? (lockedMessage ?? 'Đạo hữu cần hoàn thành toàn bộ nhiệm vụ hôm nay để mở khóa phiên mới.')
                              : 'AI biến mục tiêu lớn thành nhiệm vụ vừa sức.',
                          style: TextStyle(
                            color: isLocked ? const Color(0xFFFBBF24).withValues(alpha: 0.85) : const Color(0xFF8BA5BA),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Input Bar with Arrow / Lock Button
              GestureDetector(
                onTap: isLocked ? onLockedTap : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFF161922).withValues(alpha: 0.60)
                        : const Color(0xFF061424).withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isLocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.40)
                          : const Color(0xFFC59A44).withValues(alpha: 0.55),
                      width: 1.1,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 16, right: 5, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: !isGeneratingAi && !isLocked,
                          style: TextStyle(
                            color: isLocked ? Colors.white54 : Colors.white,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: isLocked
                                ? 'Hoàn thành nhiệm vụ hiện tại để mở phiên mới...'
                                : 'Ví dụ: Học lập trình Flutter sau 4 tuần...',
                            hintStyle: TextStyle(
                              color: isLocked
                                  ? const Color(0xFFD97706).withValues(alpha: 0.70)
                                  : const Color(0xFF7E98AE),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) {
                            if (isLocked) {
                              onLockedTap?.call();
                            } else {
                              onSubmitted();
                            }
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: isGeneratingAi
                            ? null
                            : (isLocked ? onLockedTap : onSubmitted),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFF271C12).withValues(alpha: 0.65)
                                : const Color(0xFF0A1D30).withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isLocked
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.60)
                                  : const Color(0xFFC59A44).withValues(alpha: 0.70),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: isGeneratingAi
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFF2C465),
                                    ),
                                  )
                                : Icon(
                                    isLocked ? Icons.lock_outline_rounded : Icons.arrow_forward_rounded,
                                    color: isLocked ? const Color(0xFFFBBF24) : const Color(0xFFF2C465),
                                    size: 20,
                                  ),
                          ),
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
