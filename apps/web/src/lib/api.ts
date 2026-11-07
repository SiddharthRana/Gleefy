import { currentAccessToken } from './supabase';

export const API_URL = (process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000').replace(
  /\/$/,
  '',
);

export interface ApiErrorBody {
  statusCode?: number;
  code?: string;
  message?: string | string[];
}

export class ApiError extends Error {
  constructor(
    readonly status: number | null,
    readonly body: ApiErrorBody | null,
  ) {
    super(body?.code ?? (status === null ? 'network' : `http_${status}`));
  }
  get code(): string | undefined {
    return this.body?.code;
  }
}

/** Calls the MirthMix API, sending the purchaser's access token when signed in. */
export async function apiFetch<T>(
  path: `/v1/${string}`,
  init: { method?: 'GET' | 'POST' | 'DELETE'; body?: unknown; timeoutMs?: number } = {},
): Promise<T> {
  const token = await currentAccessToken();
  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      method: init.method ?? 'GET',
      headers: {
        ...(init.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: init.body !== undefined ? JSON.stringify(init.body) : undefined,
      signal: init.timeoutMs ? AbortSignal.timeout(init.timeoutMs) : undefined,
    });
  } catch {
    throw new ApiError(null, null);
  }
  const data = (await res.json().catch(() => null)) as unknown;
  if (!res.ok) throw new ApiError(res.status, data as ApiErrorBody | null);
  return data as T;
}

/** Turns an API error (or a network failure) into a message safe to show people. */
export function errorMessage(err: unknown): string {
  if (err instanceof ApiError && err.body) {
    const { message, code, statusCode } = err.body;
    if (typeof message === 'string' && code) return message;
    if (statusCode === 401) return 'Your session has expired. Please sign in again.';
    if (statusCode === 429) return 'Too many requests. Please wait a minute and try again.';
  }
  return 'We couldn’t reach MirthMix. Check your connection and try again.';
}
