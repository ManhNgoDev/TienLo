import 'package:flutter/material.dart';
import '../../../domain/shop_item_model.dart';

class ShopInventoryView extends StatelessWidget {
  final List<UserInventoryItemModel> inventory;
  final VoidCallback onGoToShop;

  const ShopInventoryView({
    super.key,
    required this.inventory,
    required this.onGoToShop,
  });

  @override
  Widget build(BuildContext context) {
    if (inventory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E2E).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC59A44).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFF2C465),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Túi Càn Khôn Trống',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đạo hữu chưa sở hữu vật phẩm tu tiên nào. Hãy ghé Cửa Hàng để đổi lấy Phù Lục & Đan Dược trợ lực tu vi!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8BA5BA),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onGoToShop,
                icon: const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Xem Cửa Hàng',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC59A44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: inventory.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = inventory[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF091726).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC59A44).withValues(alpha: 0.45),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2235),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF2C465).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.iconData,
                    color: const Color(0xFFF2C465),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC59A44).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF2C465).withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.effect,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
