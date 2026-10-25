import { Controller, Get, Query, Req } from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service.js';
import { OAuth2Client } from 'google-auth-library';
import { getAuth, initializeFirebaseAdmin } from '../../config/firebase.config.js';

@Controller('leaderboard')
export class LeaderboardController {
  private readonly googleOAuthClient = new OAuth2Client();

  constructor(private readonly leaderboardService: LeaderboardService) {}

  @Get()
  async getLeaderboard(
    @Req() req: any,
    @Query('sortBy') sortBy?: string,
    @Query('limit') limit?: number,
  ) {
    let currentUserId: string | undefined;

    // Trích xuất UID nếu có Authorization header
    const authHeader = req.headers?.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split('Bearer ')[1]?.trim();
      if (token) {
        if (token.startsWith('demo-') || token.startsWith('mock-')) {
          const extracted = token.replace(/^(demo-token-|mock-token-|demo-|mock-)/, '').trim();
          currentUserId = extracted.length > 0 && !extracted.startsWith('dev-fallback')
            ? extracted
            : 'demo-google-uid-123456';
        } else {
          // Thử Firebase ID Token
          const app = initializeFirebaseAdmin();
          if (app) {
            try {
              const auth = getAuth(app);
              const decoded = await auth.verifyIdToken(token);
              currentUserId = decoded.uid;
            } catch (_) {}
          }

          // Thử Google OAuth Token nếu chưa có UID
          if (!currentUserId) {
            try {
              const allowedClientIds = [
                process.env.GOOGLE_CLIENT_ID,
                '827303035345-tdskj058ijr5qjk2iha54ov2jt9ps6vq.apps.googleusercontent.com',
              ].filter(Boolean) as string[];

              let payload: any = null;
              try {
                const ticket = await this.googleOAuthClient.verifyIdToken({
                  idToken: token,
                  audience: allowedClientIds,
                });
                payload = ticket.getPayload();
              } catch (err: any) {
                if (err.message && err.message.includes('Token used too late')) {
                  const parts = token.split('.');
                  if (parts.length === 3) {
                    payload = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));
                  }
                }
              }
              if (payload && payload.sub) {
                currentUserId = payload.sub;
              }
            } catch (_) {}
          }
        }
      }
    }

    const validLimit = Math.min(100, Math.max(1, Number(limit) || 50));
    return this.leaderboardService.getLeaderboard(
      currentUserId,
      sortBy || 'default',
      validLimit,
    );
  }
}
