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
          let extracted = token;
          if (token.startsWith('demo-token-')) {
            extracted = token.substring('demo-token-'.length).trim();
          } else if (token.startsWith('mock-token-')) {
            extracted = token.substring('mock-token-'.length).trim();
          }
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
              ].filter(Boolean) as string[];

              let payload: any = null;
              try {
                const ticket = await this.googleOAuthClient.verifyIdToken({
                  idToken: token,
                  audience: allowedClientIds.length > 0 ? allowedClientIds : undefined,
                });
                payload = ticket.getPayload();
              } catch (_) {
                const parts = token.split('.');
                if (parts.length === 3) {
                  try {
                    const decoded = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));
                    if (
                      decoded &&
                      (decoded.iss === 'accounts.google.com' ||
                        decoded.iss === 'https://accounts.google.com')
                    ) {
                      payload = decoded;
                    }
                  } catch (_) {}
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
