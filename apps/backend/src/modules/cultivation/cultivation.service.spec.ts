import { describe, it, expect, beforeEach, vi } from 'vitest';
import { CultivationService } from './cultivation.service.js';
import { CULTIVATION_REALMS } from './cultivation.constants.js';

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

  it('should breakthrough from Phàm Nhân to Luyện Khí Bậc 1 when reaching 1000 EXP', async () => {
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

  it('should breakthrough to next realm (Kết Đan) when reaching Bậc 10 + 100% EXP in Luyện Khí', async () => {
    // First reach Luyện Khí Bậc 1 (1000 EXP), then 10 bậc * 1000 EXP = 10,000 EXP => total 11,000 + 500 = 11,500 EXP
    const result = await service.addExp('test-user-breakthrough', 11500);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(true);
    expect(result.profile.realmIndex).toBe(2);
    expect(result.profile.realmName).toBe('Kết Đan');
    expect(result.profile.subRealm).toBe(1);
    expect(result.profile.maxExp).toBe(2500); // 2.500 EXP/bậc ở Kết Đan
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
