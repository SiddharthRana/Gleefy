import * as Sentry from '@sentry/node';
import type { ErrorEvent } from '@sentry/node';

/** Where unexpected errors go. Sentry when SENTRY_DSN is set; otherwise only the log. */
export interface ErrorReporter {
  readonly enabled: boolean;
  capture(error: unknown, context?: Record<string, string | number | undefined>): void;
}

export const ERROR_REPORTER = Symbol('ERROR_REPORTER');

export class NoopErrorReporter implements ErrorReporter {
  readonly enabled = false;
  capture(): void {}
}

const SENSITIVE_HEADERS = new Set([
  'authorization',
  'cookie',
  'paddle-signature',
  'webhook-signature',
  'x-forwarded-for',
  'x-real-ip',
  'cf-connecting-ip',
]);

/**
 * Removes personal data before an event leaves the server: user identity, IPs, cookies, auth and
 * signature headers, request bodies (purchase tokens, webhook payloads with emails) and query
 * strings. Ported from Weblume.
 */
export function scrubEvent(event: ErrorEvent): ErrorEvent {
  delete event.user;
  if (event.request) {
    const r = event.request;
    delete r.cookies;
    delete r.data;
    delete r.query_string;
    if (r.url) r.url = r.url.split('?')[0]!;
    if (r.headers) {
      for (const k of Object.keys(r.headers))
        if (SENSITIVE_HEADERS.has(k.toLowerCase())) delete r.headers[k];
    }
    delete r.env;
  }
  if (event.breadcrumbs) {
    event.breadcrumbs = event.breadcrumbs.map((b) =>
      b.data?.url ? { ...b, data: { ...b.data, url: String(b.data.url).split('?')[0]! } } : b,
    );
  }
  return event;
}

export class SentryErrorReporter implements ErrorReporter {
  readonly enabled = true;

  constructor(
    dsn: string,
    environment: string,
    release?: string,
    /** Tests only: capture envelopes instead of sending them. */
    transport?: Sentry.NodeOptions['transport'],
  ) {
    Sentry.init({
      ...(transport ? { transport } : {}),
      dsn,
      environment,
      release,
      // Collect nothing personal; beforeSend scrubs again in case a default changes.
      dataCollection: {
        userInfo: false,
        cookies: false,
        httpHeaders: false,
        httpBodies: [],
        urlQueryParams: false,
      },
      // Errors only: no performance tracing, to stay within the free tier.
      tracesSampleRate: 0,
      // Only explicit captures from our exception filter; avoids double-reporting.
      defaultIntegrations: false,
      integrations: [Sentry.linkedErrorsIntegration(), Sentry.dedupeIntegration()],
      beforeSend: scrubEvent,
    });
  }

  capture(error: unknown, context: Record<string, string | number | undefined> = {}): void {
    Sentry.withScope((scope) => {
      for (const [k, v] of Object.entries(context)) if (v !== undefined) scope.setTag(k, String(v));
      Sentry.captureException(error);
    });
  }
}
