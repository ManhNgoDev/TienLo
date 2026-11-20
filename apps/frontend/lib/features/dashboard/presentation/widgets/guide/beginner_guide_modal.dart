import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BeginnerGuideModal extends StatefulWidget {
  const BeginnerGuideModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const BeginnerGuideModal(),
    );
  }

  @override
  State<BeginnerGuideModal> createState() => _BeginnerGuideModalState();
}

class _BeginnerGuideModalState extends State<BeginnerGuideModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'tag': 'KHỞI NGUYÊN',
      'title': 'BÍ KÍP NHẬP MÔN TIÊN LỘ',
      'subtitle': 'Hệ Thống Solo Leveling Tu Thân Đời Thực',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFFF2C465),
      'content': [
        'Chào mừng Đạo Hữu bước chân vào thế giới Tiên Lộ Tu Thân!',
        'Tiên Lộ là hệ thống biến các mục tiêu rèn luyện đời thực (học tập, thể thao, kỷ luật, công việc, ngoại hình...) thành sức mạnh tu vi và cảnh giới.',
        'Mỗi hành động kỷ luật hôm nay của đạo hữu đều được Thiên Đạo ghi nhận, gia tăng Linh Lực (EXP) và Nguyên Thạch!',
      ],
      'tip': '💡 Rèn thân như đúc kiếm, đạo tâm kiên định ắt đắc đạo phi thăng!',
    },
    {
      'tag': 'CHIẾN DỊCH & NHIỆM VỤ',
      'title': 'MỆNH LỆNH DAILY QUESTS',
      'subtitle': '5 Chỉ Tiêu Hành Động Rõ Ràng Mỗi Ngày',
      'icon': Icons.flag_rounded,
      'color': Color(0xFF38BDF8),
      'content': [
        'Nhập mục tiêu vào "Tạo Chiến Dịch", Hệ Thống AI sẽ phân tích và ban bố 5 Nhiệm vụ hàng ngày (Daily Quests).',
        'Nhiệm vụ được định lượng bằng con số đo đếm cụ thể (số cái, số phút, trang sách...) chuẩn phong cách Solo Leveling.',
        'Hoàn thành mỗi nhiệm vụ để tích lũy Linh Lực (EXP) thăng cấp và Nguyên Thạch (tiền tệ).',
      ],
      'tip': '💡 Hoàn thành đủ 5 nhiệm vụ mỗi ngày để nhận trọn vẹn điểm thưởng tối đa!',
    },
    {
      'tag': 'CẢNH GIỚI TU CHÂN',
      'title': '10 ĐẠI CẢNH GIỚI ĐỘT PHÁ',
      'subtitle': 'Từ Phàm Nhân Đến Bậc Thầy Phi Tiên',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFA855F7),
      'content': [
        'Con đường tu tiên gồm 10 cảnh giới huyền thoại: Phàm Nhân ➔ Luyện Khí ➔ Trúc Cơ ➔ Kết Đan ➔ Nguyên Anh ➔ Hóa Thần ➔ Luyện Hư ➔ Hợp Thể ➔ Đại Thừa ➔ Phi Tiên.',
        'Mỗi cảnh giới gồm 10 Bậc tu vi. Tích lũy đủ Linh Lực qua các nhiệm vụ sẽ kích hoạt Thiên Kiếp Đột Phá thăng hoa!',
        'Xem chi tiết cảnh giới bằng cách nhấn vào Thẻ Nhân Vật trên màn hình chính.',
      ],
      'tip': '💡 Đột phá cảnh giới giúp nhận thêm lượng lớn Nguyên Thạch và hào quang danh hiệu!',
    },
    {
      'tag': 'ĐẠO TÂM & KỶ LUẬT',
      'title': 'CHUỖI NGÀY & HÌNH PHẠT',
      'subtitle': 'Giữ Vững Streak • Tránh Thiên Đạo Khiển Trách',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEF4444),
      'content': [
        'Hoàn thành nhiệm vụ mỗi ngày sẽ gia tăng Chuỗi Ngày Tu Luyện (Streak) +1.',
        '⚠️ LƯU Ý CỐT TỬ: Nếu lười biếng bỏ lỡ hoặc không hoàn thành hết nhiệm vụ trong ngày, sang hôm sau sẽ bị Thiên Đạo phạt sấm sét trừ Linh Lực và có thể tụt cảnh giới!',
        'Có thể trang bị "Hộ Mệnh Phù" trong Cửa Hàng để tự động bảo vệ chuỗi ngày nếu lỡ bận việc đột xuất.',
      ],
      'tip': '💡 Duy trì kỷ luật liên tục là chìa khóa tối thượng của Thợ Săn Mạnh Nhất!',
    },
    {
      'tag': 'PHÙ LỤC CÁC & KHO ĐỒ',
      'title': 'ĐỔI BẢO VẬT & NÚT SỬ DỤNG',
      'subtitle': 'Túi Càn Khôn Chứa Đựng Vạn Vật Tu Tiên',
      'icon': Icons.inventory_2_rounded,
      'color': Color(0xFF10B981),
      'content': [
        'Vào "Phù Lục Các" để dùng Nguyên Thạch đổi lấy Đan Dược, Phù Lục thần bí và Pháp Bảo hộ mệnh.',
        'Mở tab "Túi Càn Khôn" để xem toàn bộ vật phẩm sở hữu được lưu trữ vĩnh viễn.',
        'Nhấn nút "SỬ DỤNG" trực tiếp trên từng vật phẩm để nuốt đan dược nhận ngay hàng ngàn Linh Lực (EXP) bứt phá tu vi tức khắc!',
      ],
      'tip': '💡 Đan dược cao cấp như Tẩy Tủy Đan có thể giúp đạo hữu tăng vọt cảnh giới trong nháy mắt!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF091424).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Drag indicator & Close
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (slide['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (slide['color'] as Color).withValues(alpha: 0.6),
                          width: 0.9,
                        ),
                      ),
                      child: Text(
                        slide['tag'] as String,
                        style: TextStyle(
                          color: slide['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // PageView
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    final item = _slides[index];
                    final color = item['color'] as Color;
                    final contentList = item['content'] as List<String>;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      child: Column(
                        children: [
                          // Icon
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D1E30),
                              border: Border.all(color: color, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(item['icon'] as IconData, color: color, size: 30),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Title & Subtitle
                          Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFFFF6DF),
                              fontSize: 18.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.9),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Content bullets
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06111C).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF1E3A52),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: contentList
                                  .map(
                                    (text) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 15,
                                            color: color,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: const TextStyle(
                                                color: Color(0xFFE2E8F0),
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tip Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
                            ),
                            child: Text(
                              item['tip'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Indicator & Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dots
                    Row(
                      children: List.generate(
                        _slides.length,
                        (i) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentPage == i ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? const Color(0xFFF2C465)
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Next / Start Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC59A44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      ),
                      onPressed: () {
                        if (isLast) {
                          Navigator.pop(context);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLast ? 'Bắt Đầu Tu Luyện' : 'Tiếp Tục',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
