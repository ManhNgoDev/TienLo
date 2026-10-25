import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealLifeSkillTreeCard extends StatelessWidget {
  final Map<String, dynamic>? attributes;

  const RealLifeSkillTreeCard({
    super.key,
    this.attributes,
  });

  void _showAnalysisDialog(BuildContext context, int physical, int intellect, int focus, int social) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1929).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: const Color(0xFFC59A44).withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BA5BA).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Thiên Đạo AI • Phân Tích Căn Cốt',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFFFF6DF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hệ thống tự động lượng hóa 4 thuộc tính căn cốt dựa trên thói quen và quest hoàn thành mỗi ngày của đạo hữu:',
                  style: TextStyle(
                    color: Color(0xFFBAC7D5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnalysisItem('Thể chất', '$physical%', 'Cơ bắp, thể lực, vận động, chế độ dinh dưỡng và giấc ngủ.', const Color(0xFFFB923C)),
                const SizedBox(height: 10),
                _buildAnalysisItem('Trí thức', '$intellect%', 'Đọc sách, nghiên cứu, trau dồi chuyên môn và tiếp nhận tri thức.', const Color(0xFFFDE047)),
                const SizedBox(height: 10),
                _buildAnalysisItem('Tập trung', '$focus%', 'Định lực, học sâu (Deep Work), kỷ luật, giảm phân tâm xao nhãng.', const Color(0xFF2DD4BF)),
                const SizedBox(height: 10),
                _buildAnalysisItem('Giao tiếp', '$social%', 'Tâm thái, chia sẻ, kết nối các mối quan hệ xã hội trong đời sống.', const Color(0xFFA78BFA)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      foregroundColor: const Color(0xFFFBBF24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: const Color(0xFFC59A44).withValues(alpha: 0.6)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisItem(String title, String percent, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF132235).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percent,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFF8BA5BA), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow({
    required String label,
    required double percent,
    required String percentText,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBAC7D5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFF0C1624),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * percent.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: gradientColors.last.withValues(alpha: 0.4),
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
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 36,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final physical = (attributes?['physical'] as num?)?.toInt() ?? 10;
    final intellect = (attributes?['intellect'] as num?)?.toInt() ?? 10;
    final focus = (attributes?['focus'] as num?)?.toInt() ?? 10;
    final social = (attributes?['social'] as num?)?.toInt() ?? 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SKILL TREE',
                  style: TextStyle(
                    color: Color(0xFFE8B95E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Năng Lực Đời Thực',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFF6DF),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showAnalysisDialog(context, physical, intellect, focus, social),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B95E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE8B95E).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insights, color: Color(0xFFE8B95E), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Phân tích',
                      style: TextStyle(
                        color: Color(0xFFE8B95E),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF091726).withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFC59A44).withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _buildSkillRow(
                    label: 'Thể chất',
                    percent: physical / 100.0,
                    percentText: '$physical%',
                    gradientColors: [const Color(0xFFEA580C), const Color(0xFFFB923C)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Trí thức',
                    percent: intellect / 100.0,
                    percentText: '$intellect%',
                    gradientColors: [const Color(0xFFCA8A04), const Color(0xFFFDE047)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Tập trung',
                    percent: focus / 100.0,
                    percentText: '$focus%',
                    gradientColors: [const Color(0xFF0D9488), const Color(0xFF2DD4BF)],
                  ),
                  const SizedBox(height: 14),
                  _buildSkillRow(
                    label: 'Giao tiếp',
                    percent: social / 100.0,
                    percentText: '$social%',
                    gradientColors: [const Color(0xFF7C3AED), const Color(0xFFA78BFA)],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
