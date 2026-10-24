import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { IAuthUser } from '../interfaces/auth-user.interface.js';

export const CurrentUser = createParamDecorator(
  (data: keyof IAuthUser | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user: IAuthUser = request.user;
    return data ? user?.[data] : user;
  },
);
