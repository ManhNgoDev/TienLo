class CultivationCalcUtils {
  static String formatNumber(int value) {
    if (value >= 1000000000000000) {
      final v = value / 1000000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tr.Tỷ';
    }
    if (value >= 1000000000000) {
      final v = value / 1000000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Ngàn Tỷ';
    }
    if (value >= 1000000000) {
      final v = value / 1000000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)} Tỷ';
    }
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static int calculateSubRealmExp(int realmIndex, int tier) {
    if (realmIndex == 0) return 1000;
    if (realmIndex >= 9) return 9999999999999999;

    const baseExps = {
      1: 1000,       // Luyện Khí (Tầng 1: 1.000 -> Tầng 10: 6.050)
      2: 7500,       // Kết Đan (Tầng 1: 7.500 -> Tầng 10: 44.150)
      3: 55000,      // Nguyên Anh (Tầng 1: 55.000 -> Tầng 10: 323.350)
      4: 400000,     // Hóa Thần (Tầng 1: 400.000 -> Tầng 10: 2.351.900)
      5: 3000000,    // Luyện Hư (Tầng 1: 3.000.000 -> Tầng 10: 17.638.150)
      6: 22000000,   // Đại Thừa (Tầng 1: 22.000.000 -> Tầng 10: 129.346.400)
      7: 160000000,  // Hợp Thể (Tầng 1: 160.000.000 -> Tầng 10: 940.701.800)
      8: 1200000000, // Độ Kiếp (Tầng 1: 1.200.000.000 -> Tầng 10: 7.055.263.300)
    };

    final base = baseExps[realmIndex] ?? 1000;
    final targetTier = tier.clamp(1, 10);
    if (targetTier <= 1) return base;

    double exp = base.toDouble();
    for (int t = 2; t <= targetTier; t++) {
      final factor = (1.0 + 0.10 + (t - 2) * 0.03).clamp(1.0, 1.35);
      exp = ((exp * factor) / 50).round() * 50.0;
    }
    return exp.toInt();
  }
}
