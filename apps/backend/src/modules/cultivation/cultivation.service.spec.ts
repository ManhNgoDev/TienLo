import { describe, it, expect, beforeEach, vi } from 'vitest';
import { CultivationService } from './cultivation.service.js';
import { calculateSubRealmExp } from './cultivation.constants.js';

describe('CultivationService', () => {
  let service: CultivationService;
  let mockSupabaseService: any;

  beforeEach(() => {
    mockSupabaseService = {
      getClient: vi.fn().mockReturnValue(null), // in-memory fallback
    };
    service = new CultivationService(mockSupabaseService);
  });

  it('should initialize user at Phàm Nhân with 0 EXP and 0 Nguyên Thạch', async () => {
    const profile = await service.getProfile('test-user-1');
    expect(profile.realmIndex).toBe(0);
    expect(profile.realmName).toBe('Phàm Nhân');
    expect(profile.subRealm).toBe(1);
    expect(profile.currentExp).toBe(0);
    expect(profile.maxExp).toBe(1000);
    expect(profile.spiritStones).toBe(0);
    expect(profile.allRealms.length).toBe(10);
  });

  it('should breakthrough from Phàm Nhân to Luyện Khí Tầng 1 when reaching 1000 EXP', async () => {
    // Add 1200 EXP to Phàm Nhân (maxExp = 1000)
    const result = await service.addExp('test-user-1', 1200);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(true);
    expect(result.profile.realmIndex).toBe(1);
    expect(result.profile.realmName).toBe('Luyện Khí');
    expect(result.profile.subRealm).toBe(1);
    expect(result.profile.currentExp).toBe(200);
    expect(result.profile.maxExp).toBe(1000);
  });

  it('should scale subrealm EXP from Tầng 1 to Tầng 2 by x1.1 (+0.1)', async () => {
    // Breakthrough into Luyện Khí Tầng 1 (1000 EXP) + 1000 EXP to reach Tầng 2
    // User starts at Phàm Nhân (1000 needed to reach Luyện Khí Tầng 1)
    // Then 1000 needed to advance to Luyện Khí Tầng 2
    // Total 2050 EXP => Luyện Khí Tầng 2 with 50 EXP
    const result = await service.addExp('test-user-scale', 2050);
    expect(result.profile.realmIndex).toBe(1);
    expect(result.profile.subRealm).toBe(2);
    expect(result.profile.currentExp).toBe(50);
    // Tầng 2 requires 1100 EXP (1000 * 1.1)
    expect(result.profile.maxExp).toBe(1100);
    expect(calculateSubRealmExp(1, 2)).toBe(1100);
    expect(calculateSubRealmExp(1, 3)).toBe(1250);
    expect(calculateSubRealmExp(1, 10)).toBe(6050);
  });

  it('should breakthrough to next realm (Kết Đan) when reaching Tầng 10 + 100% EXP in Luyện Khí', async () => {
    // 1000 (Phàm Nhân) + 25400 (Tổng 10 tầng Luyện Khí) + 500 = 26900 EXP
    const result = await service.addExp('test-user-breakthrough', 26900);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(true);
    expect(result.profile.realmIndex).toBe(2);
    expect(result.profile.realmName).toBe('Kết Đan');
    expect(result.profile.subRealm).toBe(1);
    expect(result.profile.maxExp).toBe(7500); // 7.500 Linh Lực Tầng 1 ở Kết Đan (tiếp nối từ 6.050 của Luyện Khí Tầng 10)
    expect(result.profile.currentExp).toBe(500);
  });

  it('should correctly add and spend spirit stones', async () => {
    await service.getProfile('test-user-stones'); // starts with 0
    const afterEarn = await service.addSpiritStones('test-user-stones', 30, 'Thưởng nhiệm vụ');
    expect(afterEarn.spiritStones).toBe(30);

    const afterSpend = await service.addSpiritStones('test-user-stones', -25, 'Mua đan dược');
    expect(afterSpend.spiritStones).toBe(5);
  });

  describe('penalizeExp & Degradation Rules', () => {
    it('should degrade subrealm from Luyện Khí Tầng 2 to Tầng 1 when penalized', async () => {
      // Setup user at Luyện Khí Tầng 2 with 50 Linh Lực
      await service.addExp('test-user-demote-sub', 2050);
      const penalty = await service.penalizeExp('test-user-demote-sub', 1, 200, 'Bỏ lỡ nhiệm vụ');
      expect(penalty.demotedLevel).toBe(true);
      expect(penalty.demotedRealm).toBe(false);
      expect(penalty.previousSubRealm).toBe(2);
      expect(penalty.currentSubRealm).toBe(1);
      expect(penalty.currentRealmName).toBe('Luyện Khí');
      // Tầng 1 has maxExp = 1000. 50 - 200 = -150 => 1000 - 150 = 850
      expect(penalty.profile.currentExp).toBe(850);
      expect(penalty.profile.maxExp).toBe(1000);
    });

    it('should NOT degrade from Luyện Khí Tầng 1 to Phàm Nhân, stops at Luyện Khí Tầng 1 (0 Linh Lực)', async () => {
      // User advances to Luyện Khí Tầng 1 with 200 Linh Lực
      await service.addExp('test-user-protect', 1200);
      const penalty = await service.penalizeExp('test-user-protect', 3, 500, 'Bỏ lỡ 3 nhiệm vụ');
      // User must stay in Luyện Khí Tầng 1 with 0 Linh Lực
      expect(penalty.demotedRealm).toBe(false);
      expect(penalty.profile.realmIndex).toBe(1);
      expect(penalty.profile.realmName).toBe('Luyện Khí');
      expect(penalty.profile.subRealm).toBe(1);
      expect(penalty.profile.currentExp).toBe(0);
      expect(penalty.profile.maxExp).toBe(1000);
    });

    it('should demote realm from Kết Đan Tầng 1 to Luyện Khí Tầng 10 when penalized', async () => {
      // Breakthrough into Kết Đan Tầng 1 with 500 Linh Lực
      await service.addExp('test-user-demote-realm', 26900);
      const penalty = await service.penalizeExp('test-user-demote-realm', 2, 800, 'Bỏ lỡ nhiệm vụ Kết Đan');
      expect(penalty.demotedLevel).toBe(true);
      expect(penalty.demotedRealm).toBe(true);
      expect(penalty.previousRealmName).toBe('Kết Đan');
      expect(penalty.previousSubRealm).toBe(1);
      expect(penalty.currentRealmName).toBe('Luyện Khí');
      expect(penalty.currentSubRealm).toBe(10);
      // Luyện Khí Tầng 10 maxExp = 6050. 500 - 800 = -300 => 6050 - 300 = 5750
      expect(penalty.profile.currentExp).toBe(5750);
      expect(penalty.profile.maxExp).toBe(6050);
    });
  });
});
