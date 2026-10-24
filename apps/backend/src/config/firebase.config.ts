import { Logger } from '@nestjs/common';
import { initializeApp, getApps, getApp, cert, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const logger = new Logger('FirebaseAdmin');

let isFirebaseInitialized = false;

export function initializeFirebaseAdmin(): App | null {
  if (isFirebaseInitialized || getApps().length > 0) {
    return getApp();
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (privateKey) {
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
      privateKey = privateKey.slice(1, -1);
    }
    if (privateKey.startsWith("'") && privateKey.endsWith("'")) {
      privateKey = privateKey.slice(1, -1);
    }
    privateKey = privateKey.replace(/\\n/g, '\n');
  }

  if (projectId && clientEmail && privateKey) {
    try {
      const app = initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });
      isFirebaseInitialized = true;
      logger.log(`Firebase Admin initialized successfully for project: ${projectId}`);
      return app;
    } catch (error) {
      logger.error('Failed to initialize Firebase Admin SDK', error);
      return null;
    }
  } else {
    logger.warn(
      'Firebase Admin credentials not found in environment variables. Running in DEVELOPMENT mode with simulated/demo token verification enabled.',
    );
    return null;
  }
}

export { getAuth };
