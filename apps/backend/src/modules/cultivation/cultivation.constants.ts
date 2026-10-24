export interface CultivationRealmConfig {
  index: number;
  name: string;
  subRealms: number; // 1-10 tầng
  expPerSubRealm: number; // Base EXP của Tầng 1
  minExp: number; // EXP tầng 1
  maxExp: number; // EXP tầng 10
  title: string;
}

/**
 * Tính toán lượng EXP cần thiết để thăng cấp tầng `subRealm` (1..10) trong cảnh giới `realmIndex`.
 * Quy tắc:
 * - Phàm Nhân (realm 0): 1.000 EXP để đột phá vào Luyện Khí.
 * - Từ Luyện Khí (realm 1..8): mỗi cảnh giới có 10 tầng (Tầng 1 đến 10).
 *   Mỗi tầng sau sẽ gấp tầng trước bắt đầu từ x0.1 (tức 1.1x) và nâng dần (+0.1 mỗi tầng), không được gấp quá x5.0.
 * - Phi Tiên (realm 9): 9.999.999 EXP (Cực Cảnh).
 */
export function calculateSubRealmExp(realmIndex: number, subRealm: number): number {
  if (realmIndex === 0) return 1000;
  if (realmIndex >= 9) return 9999999999999999;

  const baseExps: Record<number, number> = {
    1: 1000,           // Luyện Khí (Tầng 1: 1.000 -> Tầng 10: 33.550)
    2: 35000,          // Kết Đan (Tầng 1: 35.000 -> Tầng 10: 1.173.050)
    3: 1250000,        // Nguyên Anh (Tầng 1: 1.250.000 -> Tầng 10: 41.902.700)
    4: 45000000,       // Hóa Thần (Tầng 1: 45.000.000 -> Tầng 10: 1.508.495.800)
    5: 1600000000,     // Luyện Hư (Tầng 1: 1.600.000.000 -> Tầng 10: 53.635.405.800)
    6: 55000000000,    // Đại Thừa (Tầng 1: 55.000.000.000 -> Tầng 10: 1.843.717.075.200)
    7: 2000000000000,  // Hợp Thể (Tầng 1: 2.000.000.000.000 -> Tầng 10: 67.044.257.280.000)
    8: 70000000000000, // Độ Kiếp (Tầng 1: 70.000.000.000.000 -> Tầng 10: 2.346.549.004.800.000)
  };

  const base = baseExps[realmIndex] || 1000;
  const targetTier = Math.max(1, Math.min(subRealm, 10));
  if (targetTier <= 1) return base;

  let exp = base;
  for (let t = 2; t <= targetTier; t++) {
    // Tầng 2: 1.10x (+0.10)
    // Tầng 3: 1.20x (+0.20)
    // ...
    // Capped at 5.0x
    const factor = Math.min(5.0, 1.0 + 0.1 + (t - 2) * 0.1);
    exp = Math.round((exp * factor) / 50) * 50;
  }
  return exp;
}

export const CULTIVATION_REALMS: CultivationRealmConfig[] = [
  { index: 0, name: 'Phàm Nhân', subRealms: 1, expPerSubRealm: 1000, minExp: 1000, maxExp: 1000, title: 'Phàm Thai Chưa Tỉnh' },
  { index: 1, name: 'Luyện Khí', subRealms: 10, expPerSubRealm: 1000, minExp: 1000, maxExp: 33550, title: 'Luyện Khí Kỳ Tu Sĩ' },
  { index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 35000, minExp: 35000, maxExp: 1173050, title: 'Kim Đan Đại Sư' },
  { index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 1250000, minExp: 1250000, maxExp: 41902700, title: 'Nguyên Anh Lão Tổ' },
  { index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 45000000, minExp: 45000000, maxExp: 1508495800, title: 'Hóa Thần Chân Quân' },
  { index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 1600000000, minExp: 1600000000, maxExp: 53635405800, title: 'Luyện Hư Chí Tôn' },
  { index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 55000000000, minExp: 55000000000, maxExp: 1843717075200, title: 'Đại Thừa Cường Giả' },
  { index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 2000000000000, minExp: 2000000000000, maxExp: 67044257280000, title: 'Hợp Thể Tiên Tôn' },
  { index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 70000000000000, minExp: 70000000000000, maxExp: 2346549004800000, title: 'Chuẩn Tiên Thiên Kiếp' },
  { index: 9, name: 'Phi Tiên', subRealms: 1, expPerSubRealm: 0, minExp: 0, maxExp: 0, title: 'Chân Tiên Phi Thăng' },
];

export enum QuestDifficulty {
  EASY = 'EASY',         // Cấp 1: Dễ
  MEDIUM = 'MEDIUM',     // Cấp 2: Vừa
  HARD = 'HARD',         // Cấp 3: Khó
  BREAKTHROUGH = 'BREAKTHROUGH', // Cấp 4: Đột Phá
}

export interface DifficultyRewardTier {
  minExp: number;
  maxExp: number;
  minStones: number;
  maxStones: number;
  label: string;
}

export const DIFFICULTY_REWARDS: Record<QuestDifficulty, DifficultyRewardTier> = {
  [QuestDifficulty.EASY]: {
    minExp: 80,
    maxExp: 120,
    minStones: 10,
    maxStones: 15,
    label: 'Dễ',
  },
  [QuestDifficulty.MEDIUM]: {
    minExp: 150,
    maxExp: 250,
    minStones: 20,
    maxStones: 30,
    label: 'Vừa',
  },
  [QuestDifficulty.HARD]: {
    minExp: 300,
    maxExp: 500,
    minStones: 40,
    maxStones: 60,
    label: 'Khó',
  },
  [QuestDifficulty.BREAKTHROUGH]: {
    minExp: 1000,
    maxExp: 2000,
    minStones: 100,
    maxStones: 200,
    label: 'Đột Phá',
  },
};
