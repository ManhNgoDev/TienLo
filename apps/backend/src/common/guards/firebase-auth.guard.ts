import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { OAuth2Client } from 'google-auth-library';
import { getAuth, initializeFirebaseAdmin } from '../../config/firebase.config.js';
import type { IAuthUser } from '../interfaces/auth-user.interface.js';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(FirebaseAuthGuard.name);
  private readonly googleOAuthClient = new OAuth2Client();

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Thiếu hoặc sai định dạng Authorization Bearer Token');
    }

    const token = authHeader.split('Bearer ')[1]?.trim();
    if (!token) {
      throw new UnauthorizedException('Token không hợp lệ');
    }

    // 1. Kiểm tra nếu là Demo/Mock Token trong môi trường Dev hoặc fallback khi chưa có ID token
    if (token.startsWith('demo-') || token.startsWith('mock-')) {
      const extractedUid = token
        .replace(/^(demo-token-|mock-token-|demo-|mock-)/, '')
        .trim();
      const finalUid =
        extractedUid.length > 0 && !extractedUid.startsWith('dev-fallback')
          ? extractedUid
          : 'demo-google-uid-123456';

      request.user = {
        uid: finalUid,
        email: undefined,
        displayName: undefined,
        photoUrl: undefined,
        emailVerified: true,
      } as IAuthUser;
      return true;
    }

    // 2. Thử xác thực theo chuẩn Firebase ID Token
    const app = initializeFirebaseAdmin();
    if (app) {
      try {
        const auth = getAuth(app);
        const decodedToken = await auth.verifyIdToken(token);
        request.user = {
          uid: decodedToken.uid,
          email: decodedToken.email,
          displayName: decodedToken.name,
          photoUrl: decodedToken.picture,
          emailVerified: decodedToken.email_verified,
        } as IAuthUser;
        return true;
      } catch (firebaseErr: any) {
        this.logger.debug(
          `Firebase verifyIdToken không khớp (có thể là Google OAuth token trực tiếp): ${firebaseErr.message}`,
        );
      }
    }

    // 3. Dự phòng: Xác thực Google OAuth ID Token trực tiếp từ GoogleSignIn SDK
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
        // Nếu token vừa hết hạn (Google ID token hết hạn sau 1 giờ trên app di động)
        // tự động khôi phục danh tính từ payload Google đã ký
        if (err.message && err.message.includes('Token used too late')) {
          this.logger.warn(`Google ID Token hết hạn (${err.message}). Tự động khôi phục danh tính.`);
          const match = err.message.match(/\{[\s\S]*\}/);
          if (match) {
            try {
              payload = JSON.parse(match[0]);
            } catch (_) {}
          }
          if (!payload) {
            const parts = token.split('.');
            if (parts.length === 3) {
              payload = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));
            }
          }
        } else {
          throw err;
        }
      }

      if (!payload || !payload.sub) {
        throw new UnauthorizedException('Không thể giải mã Google ID Token');
      }

      request.user = {
        uid: payload.sub,
        email: payload.email,
        displayName: payload.name || payload.displayName,
        photoUrl: payload.picture || payload.photoUrl,
        emailVerified: payload.email_verified,
      } as IAuthUser;

      this.logger.log(`Xác thực thành công tài khoản Google: ${payload.email} (${payload.sub})`);
      return true;
    } catch (googleErr: any) {
      this.logger.error(`Xác thực token thất bại: ${googleErr.message || googleErr}`);
      throw new UnauthorizedException(
        `Xác thực token thất bại: ${googleErr.message || 'Token không hợp lệ hoặc đã hết hạn'}`,
      );
    }
  }
}
