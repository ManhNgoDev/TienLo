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
    expect(calculateSubRealmExp(1, 3)).toBe(1300);
    expect(calculateSubRealmExp(1, 10)).toBe(33550);
  });

  it('should breakthrough to next realm (Kết Đan) when reaching Tầng 10 + 100% EXP in Luyện Khí', async () => {
    // 1000 (Phàm Nhân) + 77850 (Tổng 10 tầng Luyện Khí) + 500 = 79350 EXP
    const result = await service.addExp('test-user-breakthrough', 79350);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(true);
    expect(result.profile.realmIndex).toBe(2);
    expect(result.profile.realmName).toBe('Kết Đan');
    expect(result.profile.subRealm).toBe(1);
    expect(result.profile.maxExp).toBe(35000); // 35.000 Linh Lực Tầng 1 ở Kết Đan (tiếp nối từ 33.550 của Luyện Khí Tầng 10)
    expect(result.profile.currentExp).toBe(500);
  });

  it('should correctly add and spend spirit stones', async () => {
    await service.getProfile('test-user-stones'); // starts with 0
    const afterEarn = await service.addSpiritStones('test-user-stones', 30, 'Thưởng nhiệm vụ');
    expect(afterEarn.spiritStones).toBe(30);

    const afterSpend = await service.addSpiritStones('test-user-stones', -25, 'Mua đan dược');
    expect(afterSpend.spiritStones).toBe(5);
  });
});
