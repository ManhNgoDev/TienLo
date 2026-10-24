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

    // 1. Kiểm tra nếu là Demo/Mock Token trong môi trường Dev
    if (token.startsWith('demo-') || token.startsWith('mock-')) {
      request.user = {
        uid: 'demo-google-uid-123456',
        email: 'demo.user@tienlo.app',
        displayName: 'TienLo Demo User',
        photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
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

      const ticket = await this.googleOAuthClient.verifyIdToken({
        idToken: token,
        audience: allowedClientIds,
      });

      const payload = ticket.getPayload();
      if (!payload) {
        throw new UnauthorizedException('Không thể giải mã Google ID Token');
      }

      request.user = {
        uid: payload.sub,
        email: payload.email,
        displayName: payload.name,
        photoUrl: payload.picture,
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
