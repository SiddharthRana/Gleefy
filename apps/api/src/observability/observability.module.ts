import { Global, Module } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { ENV, type Env } from '../config/env';
import { ERROR_REPORTER, NoopErrorReporter, SentryErrorReporter } from './error-reporter';
import { ReportingExceptionFilter } from './reporting-exception.filter';

/** Optional error reporting: Sentry when SENTRY_DSN is set, otherwise the log only. */
@Global()
@Module({
  providers: [
    {
      provide: ERROR_REPORTER,
      inject: [ENV],
      useFactory: (env: Env) =>
        env.SENTRY_DSN
          ? new SentryErrorReporter(
              env.SENTRY_DSN,
              env.SENTRY_ENVIRONMENT ?? env.NODE_ENV,
              process.env.npm_package_version,
            )
          : new NoopErrorReporter(),
    },
    { provide: APP_FILTER, useClass: ReportingExceptionFilter },
  ],
  exports: [ERROR_REPORTER],
})
export class ObservabilityModule {}
