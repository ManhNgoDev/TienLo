export interface ShopItem {
  id: string;
  name: string;
  category: 'talisman' | 'pill' | 'treasure' | 'material';
  categoryName: string;
  description: string;
  effect: string;
  price: number;
  rarity: 'THƯỜNG' | 'QUÝ' | 'CỰC HIẾM' | 'TIÊN PHẨM';
  badge?: string;
  iconType: string;
  isAvailable: boolean;
}

export const DEFAULT_SHOP_ITEMS: ShopItem[] = [
  // 1. Phù Lục (Talismans & Runes)
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },

  // 2. Đan Dược (Pills & Elixirs)
  {
    id: 'dan_tu_khi',
    name: 'Tụ Khí Đan',
    category: 'pill',
    categoryName: 'Đan Dược',
    description: 'Đan dược cơ bản bồi bổ chân khí, gia tăng tốc độ tích lũy tu vi sơ cấp.',
    effect: 'Uống vào lập tức nhận ngay +250 điểm Linh Lực (EXP).',
    price: 45,
    rarity: 'THƯỜNG',
    iconType: 'medication',
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },

  // 3. Pháp Bảo & Linh Tài (Treasures & Artifacts)
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
  {
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
    isAvailable: true,
  },
];
