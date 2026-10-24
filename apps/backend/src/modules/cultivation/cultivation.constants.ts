export interface CultivationRealmConfig {
  index: number;
  name: string;
  subRealms: number; // 1-10
  expPerSubRealm: number;
  title: string;
}

export const CULTIVATION_REALMS: CultivationRealmConfig[] = [
  { index: 0, name: 'Phàm Nhân', subRealms: 1, expPerSubRealm: 1000, title: 'Phàm Thai Chưa Tỉnh' },
  { index: 1, name: 'Luyện Khí', subRealms: 10, expPerSubRealm: 1000, title: 'Luyện Khí Kỳ Tu Sĩ' },
  { index: 2, name: 'Kết Đan', subRealms: 10, expPerSubRealm: 2500, title: 'Kim Đan Đại Sư' },
  { index: 3, name: 'Nguyên Anh', subRealms: 10, expPerSubRealm: 5000, title: 'Nguyên Anh Lão Tổ' },
  { index: 4, name: 'Hóa Thần', subRealms: 10, expPerSubRealm: 10000, title: 'Hóa Thần Chân Quân' },
  { index: 5, name: 'Luyện Hư', subRealms: 10, expPerSubRealm: 20000, title: 'Luyện Hư Chí Tôn' },
  { index: 6, name: 'Đại Thừa', subRealms: 10, expPerSubRealm: 40000, title: 'Đại Thừa Cường Giả' },
  { index: 7, name: 'Hợp Thể', subRealms: 10, expPerSubRealm: 80000, title: 'Hợp Thể Tiên Tôn' },
  { index: 8, name: 'Độ Kiếp', subRealms: 10, expPerSubRealm: 150000, title: 'Chuẩn Tiên Thiên Kiếp' },
  { index: 9, name: 'Phi Tiên', subRealms: 1, expPerSubRealm: 0, title: 'Chân Tiên Phi Thăng' },
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
