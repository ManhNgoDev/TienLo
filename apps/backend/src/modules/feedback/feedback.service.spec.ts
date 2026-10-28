import { describe, it, expect, vi, beforeEach } from 'vitest';
import { FeedbackService } from './feedback.service.js';
import { SupabaseService } from '../database/supabase.service.js';

describe('FeedbackService', () => {
  let feedbackService: FeedbackService;
  let mockSupabaseService: SupabaseService;

  beforeEach(() => {
    mockSupabaseService = {
      getClient: vi.fn().mockReturnValue(null),
      getInMemoryUsers: vi.fn().mockReturnValue([]),
    } as unknown as SupabaseService;

    feedbackService = new FeedbackService(mockSupabaseService);
  });

  it('phải tiếp nhận báo cáo lỗi ngay lập tức mà không chặn HTTP request', async () => {
    const t0 = Date.now();
    const result = await feedbackService.reportBug({
      title: 'Lỗi đăng nhập',
      description: 'Không thể đăng nhập bằng tài khoản Google',
      category: 'LOGIN',
      screen: 'LoginScreen',
      userEmail: 'user@tienlo.app',
      sentByClient: true,
    });

    const elapsed = Date.now() - t0;
    expect(elapsed).toBeLessThan(100); // Phản hồi tức thì dưới 100ms
    expect(result.success).toBe(true);
    expect(result.reportId).toBeDefined();

    const recents = feedbackService.getRecentReports();
    expect(recents.length).toBeGreaterThan(0);
    expect(recents[0].title).toBe('Lỗi đăng nhập');
    expect(recents[0].sentEmail).toBe(true);
  });
});
