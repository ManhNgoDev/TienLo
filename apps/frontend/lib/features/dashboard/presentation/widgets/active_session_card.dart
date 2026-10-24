import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveSessionCard extends StatelessWidget {
  final String activeCampaignTitle;
  final int campaignCurrentDay;
  final int campaignTotalDays;
  final int completedCount;

  const ActiveSessionCard({
    super.key,
    required this.activeCampaignTitle,
    required this.campaignCurrentDay,
    required this.campaignTotalDays,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (activeCampaignTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    final double dayProgress = (campaignCurrentDay / campaignTotalDays).clamp(0.0, 1.0);
    final int daysRemaining = (campaignTotalDays - campaignCurrentDay).clamp(0, 999);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF07121E).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFC59A44),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Session Tag + Day Pill Badge (Responsive with Expanded & Flexible)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F261C),
                            border: Border.all(color: const Color(0xFF10B981), width: 1),
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'PHIÊN TU LUYỆN (SESSION)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF70BFE6),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC59A44).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC59A44).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Ngày $campaignCurrentDay/$campaignTotalDays',
                      style: const TextStyle(
                        color: Color(0xFFF2C465),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Campaign Goal Title
              Text(
                activeCampaignTitle,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFF6DF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // Row 3: Progress Bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1624),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          width: constraints.maxWidth * dayProgress,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                blurRadius: 4,
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

              // Row 4: Details footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    daysRemaining > 0 ? 'Còn $daysRemaining ngày tu luyện' : 'Ngày cuối cùng của chiến dịch!',
                    style: const TextStyle(
                      color: Color(0xFF8BA5BA),
                      fontSize: 11.5,
                    ),
                  ),
                  Text(
                    '$completedCount/3 nhiệm vụ hôm nay',
                    style: TextStyle(
                      color: completedCount == 3 ? const Color(0xFF10B981) : const Color(0xFFF2C465),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
