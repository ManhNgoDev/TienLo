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
  if (realmIndex >= 9) return 9999999;

  const baseExps: Record<number, number> = {
    1: 1000,   // Luyện Khí
    2: 2500,   // Kết Đan
    3: 5000,   // Nguyên Anh
    4: 10000,  // Hóa Thần
    5: 20000,  // Luyện Hư
    6: 40000,  // Đại Thừa
    7: 80000,  // Hợp Thể
    8: 150000, // Độ Kiếp
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
  { index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 2500, minExp: 2500, maxExp: 83800, title: 'Kim Đan Đại Sư' },
  { index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 5000, minExp: 5000, maxExp: 168250, title: 'Nguyên Anh Lão Tổ' },
  { index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 10000, minExp: 10000, maxExp: 334800, title: 'Hóa Thần Chân Quân' },
  { index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 20000, minExp: 20000, maxExp: 669850, title: 'Luyện Hư Chí Tôn' },
  { index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 40000, minExp: 40000, maxExp: 1341000, title: 'Đại Thừa Cường Giả' },
  { index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 80000, minExp: 80000, maxExp: 2681950, title: 'Hợp Thể Tiên Tôn' },
  { index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 150000, minExp: 150000, maxExp: 5028650, title: 'Chuẩn Tiên Thiên Kiếp' },
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
