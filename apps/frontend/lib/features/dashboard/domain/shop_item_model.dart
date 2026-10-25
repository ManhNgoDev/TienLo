import 'package:flutter/material.dart';

class ShopItemModel {
  final String id;
  final String name;
  final String category; // 'talisman' | 'pill' | 'treasure' | 'material'
  final String categoryName;
  final String description;
  final String effect;
  final int price;
  final String rarity; // 'THƯỜNG' | 'QUÝ' | 'CỰC HIẾM' | 'TIÊN PHẨM'
  final String? badge;
  final String iconType;
  final bool isAvailable;

  const ShopItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryName,
    required this.description,
    required this.effect,
    required this.price,
    required this.rarity,
    this.badge,
    required this.iconType,
    this.isAvailable = true,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vật Phẩm Tu Tiên',
      category: json['category']?.toString() ?? 'talisman',
      categoryName: json['categoryName']?.toString() ?? 'Phù Lục',
      description: json['description']?.toString() ?? '',
      effect: json['effect']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 50,
      rarity: json['rarity']?.toString() ?? 'THƯỜNG',
      badge: json['badge']?.toString(),
      iconType: json['iconType']?.toString() ?? 'sparkles',
      isAvailable: json['isAvailable'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryName': categoryName,
      'description': description,
      'effect': effect,
      'price': price,
      'rarity': rarity,
      'badge': badge,
      'iconType': iconType,
      'isAvailable': isAvailable,
    };
  }

  IconData get iconData {
    switch (iconType) {
      case 'shield':
        return Icons.shield_rounded;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      default:
        return Icons.token_rounded;
    }
  }

  Color get iconColor {
    switch (rarity) {
      case 'TIÊN PHẨM':
        return const Color(0xFFF59E0B); // Amber / Gold
      case 'CỰC HIẾM':
        return const Color(0xFFA855F7); // Purple
      case 'QUÝ':
        return const Color(0xFF38BDF8); // Cyan
      default:
        return const Color(0xFF34D399); // Emerald
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case 'TIÊN PHẨM':
        return const Color(0xFFFBBF24);
      case 'CỰC HIẾM':
        return const Color(0xFFC084FC);
      case 'QUÝ':
        return const Color(0xFF67E8F9);
      default:
        return const Color(0xFF6EE7B7);
    }
  }
}

class UserInventoryItemModel {
  final String id;
  final String itemId;
  final String name;
  final String category;
  final int quantity;
  final String effect;
  final String iconType;
  final String purchasedAt;

  const UserInventoryItemModel({
    required this.id,
    required this.itemId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.effect,
    required this.iconType,
    required this.purchasedAt,
  });

  factory UserInventoryItemModel.fromJson(Map<String, dynamic> json) {
    return UserInventoryItemModel(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? json['item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vật Phẩm',
      category: json['category']?.toString() ?? 'talisman',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      effect: json['effect']?.toString() ?? '',
      iconType: json['iconType']?.toString() ?? json['icon_type']?.toString() ?? 'sparkles',
      purchasedAt: json['purchasedAt']?.toString() ?? json['purchased_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'effect': effect,
      'iconType': iconType,
      'purchasedAt': purchasedAt,
    };
  }

  IconData get iconData {
    switch (iconType) {
      case 'shield':
        return Icons.shield_rounded;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'inventory_2':
        return Icons.inventory_2_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      default:
        return Icons.token_rounded;
    }
  }
}

/// Danh sách vật phẩm mặc định ban đầu tại Phù Lục Các
const List<ShopItemModel> defaultShopItemsList = [
  // 1. Phù Lục (Talismans)
  ShopItemModel(
    id: 'phu_ho_menh',
    name: 'Hộ Mệnh Phù',
    category: 'talisman',
    categoryName: 'Phù Lục',
    description: 'Thần phù do Đại Năng thượng giới luyện chế, phong ấn khí vận nghịch thiên.',
    effect: 'Tự động bảo lưu chuỗi ngày tu luyện (Streak) nếu lỡ quên làm nhiệm vụ 1 ngày.',
    price: 80,
    rarity: 'QUÝ',
    badge: 'HOT',
    iconType: 'shield',
  ),
  ShopItemModel(
    id: 'phu_tu_khi',
    name: 'Tụ Khí Phù',
    category: 'talisman',
    categoryName: 'Phù Lục',
    description: 'Phù triện dẫn dắt linh khí đất trời vào đan điền trong suốt 24 giờ.',
    effect: 'Gia tăng +50% Linh Lực (EXP) nhận được từ toàn bộ nhiệm vụ hoàn thành hôm nay.',
    price: 60,
    rarity: 'QUÝ',
    badge: 'EXP x1.5',
    iconType: 'sparkles',
  ),
  ShopItemModel(
    id: 'phu_than_hanh',
    name: 'Thần Hành Phù',
    category: 'talisman',
    categoryName: 'Phù Lục',
    description: 'Bảo phù gia trì tốc độ di chuyển, tức khắc hoàn thành 1 mục tiêu rèn luyện.',
    effect: 'Lập tức hoàn tất 1 nhiệm vụ hàng ngày bất kỳ mà không cần tốn thời gian.',
    price: 75,
    rarity: 'QUÝ',
    badge: 'TIỆN LỢI',
    iconType: 'bolt',
  ),
  ShopItemModel(
    id: 'phu_tay_tam',
    name: 'Tẩy Tâm Phù',
    category: 'talisman',
    categoryName: 'Phù Lục',
    description: 'Thanh lọc tạp niệm, hóa giải kiếp nạn và cơn thịnh nộ từ Thiên Đạo.',
    effect: 'Xóa bỏ hoàn toàn 1 lần bị phạt trừ Linh Lực do trễ hạn nhiệm vụ ngày hôm trước.',
    price: 110,
    rarity: 'CỰC HIẾM',
    badge: 'CỨU NẠN',
    iconType: 'water_drop',
  ),

  // 2. Đan Dược (Pills)
  ShopItemModel(
    id: 'dan_tu_khi',
    name: 'Tụ Khí Đan',
    category: 'pill',
    categoryName: 'Đan Dược',
    description: 'Đan dược cơ bản bồi bổ chân khí, gia tăng tốc độ tích lũy tu vi sơ cấp.',
    effect: 'Uống vào lập tức nhận ngay +250 điểm Linh Lực (EXP).',
    price: 45,
    rarity: 'THƯỜNG',
    iconType: 'medication',
  ),
  ShopItemModel(
    id: 'dan_truc_co',
    name: 'Trúc Cơ Đan',
    category: 'pill',
    categoryName: 'Đan Dược',
    description: 'Bảo đan trứ danh ngưng tụ tinh hoa nhật nguyệt, củng cố đan điền vững chắc.',
    effect: 'Uống vào lập tức nhận ngay +650 điểm Linh Lực (EXP).',
    price: 100,
    rarity: 'QUÝ',
    badge: 'PHỔ BIẾN',
    iconType: 'medication',
  ),
  ShopItemModel(
    id: 'dan_tay_tuy',
    name: 'Tẩy Tủy Đan',
    category: 'pill',
    categoryName: 'Đan Dược',
    description: 'Tuyệt phẩm linh đan tẩy kinh phạt tủy, bứt phá mọi gông cùm phàm thai.',
    effect: 'Uống vào lập tức nhận ngay +1,500 điểm Linh Lực (EXP).',
    price: 220,
    rarity: 'CỰC HIẾM',
    badge: 'BỨT PHÁ',
    iconType: 'auto_awesome',
  ),
  ShopItemModel(
    id: 'dan_co_than',
    name: 'Cố Thần Hoàn',
    category: 'pill',
    categoryName: 'Đan Dược',
    description: 'Thần đan bảo hộ nguyên thần, miễn nhiễm mọi nguy cơ rớt tầng cảnh giới.',
    effect: 'Bảo hộ vĩnh viễn không bị giáng tầng cảnh giới khi gặp hình phạt Thiên Đạo.',
    price: 160,
    rarity: 'CỰC HIẾM',
    badge: 'HỘ MỆNH',
    iconType: 'shield',
  ),

  // 3. Pháp Bảo & Linh Tài (Treasures)
  ShopItemModel(
    id: 'bao_can_khon',
    name: 'Túi Càn Khôn',
    category: 'treasure',
    categoryName: 'Pháp Bảo',
    description: 'Bên trong ẩn chứa một vùng không gian nhỏ, chứa đựng vạn vật tu tiên.',
    effect: 'Pháp bảo chứa đồ không gian vô hạn, tăng thêm 20% Nguyên Thạch nhận được từ Daily Quest.',
    price: 180,
    rarity: 'QUÝ',
    badge: 'BẢO VẬT',
    iconType: 'inventory_2',
  ),
  ShopItemModel(
    id: 'bao_tu_linh_tran',
    name: 'Tụ Linh Trận Kỳ',
    category: 'treasure',
    categoryName: 'Pháp Bảo',
    description: 'Cờ lệnh điều khiển trận pháp tụ linh, ngày đêm thu nạp linh khí tinh thuần.',
    effect: 'Vĩnh viễn tăng thêm 10% Linh Lực nhận được khi hoàn tất tất cả nhiệm vụ mỗi ngày.',
    price: 320,
    rarity: 'TIÊN PHẨM',
    badge: 'VĨNH VIỄN',
    iconType: 'flag',
  ),
  ShopItemModel(
    id: 'bao_dinh_hon_chau',
    name: 'Định Hồn Châu',
    category: 'treasure',
    categoryName: 'Pháp Bảo',
    description: 'Chí bảo thời thượng cổ, tương truyền có thể trấn áp tâm ma kiếp nạn.',
    effect: 'Nhân đôi phần thưởng Nguyên Thạch mỗi khi đạo hữu đột phá thăng cấp cảnh giới.',
    price: 550,
    rarity: 'TIÊN PHẨM',
    badge: 'CHÍ BẢO',
    iconType: 'diamond',
  ),
];
