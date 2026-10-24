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

  it('should initialize user at Luyện Khí Bậc 1 with 0 EXP and 50 Linh Thạch', async () => {
    const profile = await service.getProfile('test-user-1');
    expect(profile.realmName).toBe('Luyện Khí');
    expect(profile.subRealm).toBe(1);
    expect(profile.currentExp).toBe(0);
    expect(profile.maxExp).toBe(1000);
    expect(profile.spiritStones).toBe(50);
    expect(profile.allRealms.length).toBe(10);
  });

  it('should level up sub-realm when EXP exceeds maxExp', async () => {
    // Add 1200 EXP to Luyện Khí Bậc 1 (maxExp = 1000)
    const result = await service.addExp('test-user-1', 1200);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(false);
    expect(result.profile.subRealm).toBe(2);
    expect(result.profile.currentExp).toBe(200);
  });

  it('should breakthrough to next realm (Kết Đan) when reaching Bậc 10 + 100% EXP', async () => {
    // Level up through Luyện Khí (10 bậc * 1000 EXP = 10,000 EXP)
    const result = await service.addExp('test-user-breakthrough', 10500);
    expect(result.levelUp).toBe(true);
    expect(result.realmUp).toBe(true);
    expect(result.profile.realmIndex).toBe(2);
    expect(result.profile.realmName).toBe('Kết Đan');
    expect(result.profile.subRealm).toBe(1);
    expect(result.profile.maxExp).toBe(2500); // 2.500 EXP/bậc ở Kết Đan
    expect(result.profile.currentExp).toBe(500);
  });

  it('should correctly add and spend spirit stones', async () => {
    await service.getProfile('test-user-stones'); // starts with 50
    const afterEarn = await service.addSpiritStones('test-user-stones', 30, 'Thưởng nhiệm vụ');
    expect(afterEarn.spiritStones).toBe(80);

    const afterSpend = await service.addSpiritStones('test-user-stones', -25, 'Mua đan dược');
    expect(afterSpend.spiritStones).toBe(55);
  });
});
