import 'package:flutter/material.dart';

Color getRealmColor(int realmIndex) {
  switch (realmIndex) {
    case 0:
      return const Color(0xFF94A3B8); // Phàm Nhân: Xám bạc
    case 1:
      return const Color(0xFF34D399); // Luyện Khí: Ngọc bích
    case 2:
      return const Color(0xFFFBBF24); // Kết Đan: Kim sắc hoàng kim
    case 3:
      return const Color(0xFF818CF8); // Nguyên Anh: Lam tím linh lực
    case 4:
      return const Color(0xFFA78BFA); // Hóa Thần: Huyền tím
    case 5:
      return const Color(0xFFF472B6); // Luyện Hư: Hồng linh hoa
    case 6:
      return const Color(0xFFFB7185); // Đại Thừa: Xích diễm
    case 7:
      return const Color(0xFF38BDF8); // Hợp Thể: Băng lam cực quang
    case 8:
      return const Color(0xFFE879F9); // Độ Kiếp: Lôi kiếp tím sấm
    case 9:
      return const Color(0xFFFDE047); // Phi Tiên: Tiên quang rạng ngời
    default:
      return const Color(0xFFE5B869);
  }
}
