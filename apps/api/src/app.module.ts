import { randomUUID } from 'node:crypto';
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from 'nestjs-pino';
import type { IncomingMessage } from 'node:http';
import { AccountModule } from './account/account.module';
import { AuthModule } from './auth/auth.module';
import type { AuthUser } from './auth/auth.types';
import { BillingModule } from './billing/billing.module';
import { IpThrottlerGuard, USER_THROTTLER } from './common/throttle.guards';
import { ConfigModule } from './config/config.module';
import { ENV, type Env } from './config/env';
import { DatabaseModule } from './database/database.module';
import { EntitlementsModule } from './entitlements/entitlements.module';
import { HealthController } from './health/health.controller';
import { ObservabilityModule } from './observability/observability.module';
import { PlansController } from './plans/plans.controller';

const REQUEST_ID = /^[A-Za-z0-9-]{8,64}$/;

@Module({
  imports: [
    ConfigModule,
    LoggerModule.forRootAsync({
      inject: [ENV],
      useFactory: (env: Env) => ({
        pinoHttp: {
          level: env.LOG_LEVEL,
          transport: env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined,
          genReqId: (req: IncomingMessage) => {
            const incoming = req.headers['x-request-id'];
            return typeof incoming === 'string' && REQUEST_ID.test(incoming)
              ? incoming
              : randomUUID();
          },
          // Allow-list serializers: never log headers (auth), bodies (purchase tokens) or queries.
          serializers: {
            req: (req: { id: string; method: string; url: string }) => ({
              id: req.id,
              method: req.method,
              path: req.url.split('?')[0],
            }),
            res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
          },
        },
      }),
    }),
    ThrottlerModule.forRootAsync({
      inject: [ENV],
      useFactory: (env: Env) => [
        // Per client IP (all requests).
        { name: 'default', ttl: 60_000, limit: env.RATE_LIMIT_PER_MINUTE },
        // Per signed-in user, so rotating IPs doesn't lift the limit (UserThrottlerGuard, after auth).
        {
          name: USER_THROTTLER,
          ttl: 60_000,
          limit: env.USER_RATE_LIMIT_PER_MINUTE,
          skipIf: (ctx) => !ctx.switchToHttp().getRequest<{ user?: AuthUser }>().user,
          getTracker: (req: Record<string, unknown>) => `user:${(req.user as AuthUser).id}`,
        },
      ],
    }),
    DatabaseModule,
    ObservabilityModule,
    AuthModule,
    EntitlementsModule,
    AccountModule,
    BillingModule,
  ],
  controllers: [HealthController, PlansController],
  providers: [{ provide: APP_GUARD, useClass: IpThrottlerGuard }],
})
export class AppModule {}
