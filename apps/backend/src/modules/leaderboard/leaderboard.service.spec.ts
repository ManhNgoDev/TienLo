import { describe, it, expect, vi, beforeEach } from 'vitest';
import { LeaderboardService } from './leaderboard.service.js';
import { SupabaseService } from '../database/supabase.service.js';

describe('LeaderboardService', () => {
  let leaderboardService: LeaderboardService;
  let mockSupabaseService: SupabaseService;

  beforeEach(() => {
    mockSupabaseService = {
      getClient: vi.fn().mockReturnValue({
        from: vi.fn((table: string) => ({
          select: vi.fn().mockImplementation(() => {
            if (table === 'users') {
              return Promise.resolve({
                data: [
                  { firebase_uid: 'user-1', display_name: 'Đạo Hữu A', email: 'a@tienlo.app', avatar_url: null },
                  { firebase_uid: 'user-2', display_name: 'Đạo Hữu B', email: 'b@tienlo.app', avatar_url: null },
                  { firebase_uid: 'user-3', display_name: 'Đạo Hữu C', email: 'c@tienlo.app', avatar_url: null },
                ],
              });
            }
            if (table === 'user_cultivations') {
              return Promise.resolve({
                data: [
                  { user_id: 'user-1', streak_days: 5, realm_index: 1, sub_realm: 2, total_exp: 2500, realm_name: 'Luyện Khí' },
                  { user_id: 'user-2', streak_days: 10, realm_index: 0, sub_realm: 1, total_exp: 500, realm_name: 'Phàm Nhân' },
                  { user_id: 'user-3', streak_days: 2, realm_index: 2, sub_realm: 1, total_exp: 5000, realm_name: 'Kết Đan' },
                ],
              });
            }
            if (table === 'quests') {
              return Promise.resolve({
                data: [
                  { user_id: 'user-1', is_completed: true, is_xp_claimed: true },
                  { user_id: 'user-1', is_completed: true, is_xp_claimed: true },
                  { user_id: 'user-2', is_completed: true, is_xp_claimed: false },
                ],
              });
            }
            return Promise.resolve({ data: [] });
          }),
        })),
      }),
      getInMemoryUsers: vi.fn().mockReturnValue([]),
    } as unknown as SupabaseService;

    leaderboardService = new LeaderboardService(mockSupabaseService);
  });

  it('phải trả về người chơi thật từ database và không chứa NPC Hàn Lập hay benchmarks giả', async () => {
    const result = await leaderboardService.getLeaderboard();

    expect(result.success).toBe(true);
    expect(result.totalUsers).toBe(3);
    expect(result.leaderboard.length).toBe(3);

    // Không chứa bất kỳ NPC nào
    const containsNpc = result.leaderboard.some(u => u.isNpc || u.userId.startsWith('npc-'));
    expect(containsNpc).toBe(false);

    // Người chơi có streak cao nhất (user-2 có 10 ngày) phải đứng đầu khi sort mặc định
    expect(result.leaderboard[0].userId).toBe('user-2');
    expect(result.leaderboard[0].rank).toBe(1);
    expect(result.leaderboard[0].streakDays).toBe(10);

    // Người chơi thứ 2 là user-1 (streak 5)
    expect(result.leaderboard[1].userId).toBe('user-1');
    expect(result.leaderboard[1].rank).toBe(2);
    expect(result.leaderboard[1].completedQuestsCount).toBe(2);

    // Người chơi thứ 3 là user-3 (streak 2)
    expect(result.leaderboard[2].userId).toBe('user-3');
    expect(result.leaderboard[2].rank).toBe(3);
  });

  it('phải sắp xếp chính xác theo cảnh giới khi sortBy = realm', async () => {
    const result = await leaderboardService.getLeaderboard(undefined, 'realm');

    expect(result.success).toBe(true);
    // user-3 có realmIndex 2 (Kết Đan) phải đứng đầu
    expect(result.leaderboard[0].userId).toBe('user-3');
    expect(result.leaderboard[0].realmName).toBe('Kết Đan');
  });

  it('phải sắp xếp chính xác theo nhiệm vụ khi sortBy = quests', async () => {
    const result = await leaderboardService.getLeaderboard(undefined, 'quests');

    expect(result.success).toBe(true);
    // user-1 có 2 quests hoàn thành phải đứng đầu
    expect(result.leaderboard[0].userId).toBe('user-1');
    expect(result.leaderboard[0].completedQuestsCount).toBe(2);
  });
});
