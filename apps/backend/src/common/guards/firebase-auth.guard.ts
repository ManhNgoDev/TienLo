import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { getAuth, initializeFirebaseAdmin } from '../../config/firebase.config.js';
import type { IAuthUser } from '../interfaces/auth-user.interface.js';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
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

    // 1. Kiểm tra nếu là Demo/Mock Token trong môi trường Dev (tiện lợi khi chưa tạo Firebase Project)
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

    // 2. Xác thực với Firebase Admin SDK thực tế
    const app = initializeFirebaseAdmin();
    if (!app) {
      throw new UnauthorizedException(
        'Firebase Admin chưa được cấu hình. Hãy cấu hình FIREBASE_PROJECT_ID trong file .env hoặc sử dụng demo token (Bearer demo-token).',
      );
    }

    try {
      const auth = getAuth(app);
      const decodedToken = await auth.verifyIdToken(token);
      const authUser: IAuthUser = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        displayName: decodedToken.name,
        photoUrl: decodedToken.picture,
        emailVerified: decodedToken.email_verified,
      };

      request.user = authUser;
      return true;
    } catch (error: any) {
      throw new UnauthorizedException(`Xác thực token thất bại: ${error.message || error}`);
    }
  }
}
