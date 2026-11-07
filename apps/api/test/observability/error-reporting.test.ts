import { HttpException, HttpStatus, type ArgumentsHost } from '@nestjs/common';
import type { HttpAdapterHost } from '@nestjs/core';
import * as Sentry from '@sentry/node';
import type { ErrorEvent } from '@sentry/node';
import { afterAll, describe, expect, it, vi } from 'vitest';
import {
  scrubEvent,
  SentryErrorReporter,
  type ErrorReporter,
} from '../../src/observability/error-reporter';
import { ReportingExceptionFilter } from '../../src/observability/reporting-exception.filter';

describe('scrubEvent', () => {
  it('removes identity, cookies, auth and signature headers, bodies and query strings', () => {
    const event = scrubEvent({
      type: undefined,
      user: { id: 'u1', email: 'asha@example.com', ip_address: '203.0.113.9' },
      request: {
        url: 'https://api.gleefy.party/v1/billing/google-play/verify?x=1',
        query_string: 'x=1',
        cookies: { sb: 'x' },
        data: '{"purchaseToken":"SECRET-PURCHASE-TOKEN"}',
        headers: {
          Authorization: 'Bearer abc',
          'Paddle-Signature': 'ts=1;h1=abc',
          'X-Forwarded-For': '203.0.113.9',
          'user-agent': 'Mozilla',
        },
      },
      breadcrumbs: [{ data: { url: 'https://x.test/v1/me?y=1' } }],
    } as ErrorEvent);
    expect(event.user).toBeUndefined();
    expect(event.request).toEqual({
      url: 'https://api.gleefy.party/v1/billing/google-play/verify',
      headers: { 'user-agent': 'Mozilla' },
    });
    expect(event.breadcrumbs?.[0]?.data?.url).toBe('https://x.test/v1/me');
  });
});

describe('ReportingExceptionFilter', () => {
  const reporter = { enabled: true, capture: vi.fn<ErrorReporter['capture']>() };
  const adapter = { reply: vi.fn(), isHeadersSent: () => false, end: vi.fn() };
  const filter = new ReportingExceptionFilter(reporter, {
    httpAdapter: adapter,
  } as unknown as HttpAdapterHost);
  const host = {
    getType: () => 'http',
    getArgs: () => [],
    getArgByIndex: (i: number) => (i === 1 ? { res: true } : { req: true }),
    switchToHttp: () => ({
      getRequest: () => ({
        method: 'GET',
        route: { path: '/v1/billing/webhooks/:provider' },
        url: '/v1/billing/webhooks/paddle',
      }),
      getResponse: () => ({}),
      getNext: () => undefined,
    }),
  } as unknown as ArgumentsHost;

  it('reports unexpected errors with the route pattern only, and still answers 500', () => {
    filter.catch(new Error('db down'), host);
    expect(reporter.capture).toHaveBeenCalledWith(expect.any(Error), {
      method: 'GET',
      route: '/v1/billing/webhooks/:provider',
      status: 500,
    });
    expect(adapter.reply).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ statusCode: 500 }),
      500,
    );
  });

  it('does not report expected client errors', () => {
    reporter.capture.mockClear();
    filter.catch(new HttpException('nope', HttpStatus.NOT_FOUND), host);
    filter.catch(new HttpException('slow down', HttpStatus.TOO_MANY_REQUESTS), host);
    // e.g. body-parser's "request entity too large"
    filter.catch(Object.assign(new Error('too large'), { statusCode: 413, expose: true }), host);
    expect(reporter.capture).not.toHaveBeenCalled();
  });
});

describe('SentryErrorReporter', () => {
  afterAll(() => Sentry.close());

  it('sends scrubbed events with tags, through the Sentry SDK', async () => {
    const sent: string[] = [];
    const transport = () => ({
      send: async (envelope: unknown) => {
        sent.push(JSON.stringify(envelope));
        return {};
      },
      flush: async () => true,
    });
    const reporter = new SentryErrorReporter(
      'https://public@o0.ingest.sentry.io/1',
      'test',
      '0.0.0',
      transport,
    );
    Sentry.getIsolationScope().setUser({ email: 'asha@example.com' });
    reporter.capture(new Error('boom'), { route: '/v1/me', status: 500 });
    await Sentry.flush(2000);
    expect(sent).toHaveLength(1);
    expect(sent[0]).toContain('boom');
    expect(sent[0]).toContain('"route":"/v1/me"');
    expect(sent[0]).not.toContain('asha@example.com');
  });
});
