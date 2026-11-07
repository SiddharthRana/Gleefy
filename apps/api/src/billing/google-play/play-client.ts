import { importPKCS8, SignJWT } from 'jose';
import { ProviderError } from '../billing.types';

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

export interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

/** Accepts the key JSON raw or base64-encoded (convenient for env vars). */
export function parseServiceAccount(value: string): ServiceAccountKey {
  const text = value.trim().startsWith('{') ? value : Buffer.from(value, 'base64').toString('utf8');
  const key = JSON.parse(text) as ServiceAccountKey;
  if (!key.client_email || !key.private_key)
    throw new Error('Service account JSON is missing client_email/private_key');
  return key;
}

/** Subset of the Play Developer API ProductPurchase resource (one-time in-app products). */
export interface ProductPurchase {
  /** 0 purchased, 1 canceled (refunded or voided), 2 pending (payment not completed yet). */
  purchaseState?: number;
  /** 0 not yet acknowledged, 1 acknowledged. Unacknowledged purchases are refunded after 3 days. */
  acknowledgementState?: number;
  purchaseTimeMillis?: string;
  orderId?: string;
  obfuscatedExternalAccountId?: string;
}

export interface PlayApi {
  readonly configured: boolean;
  getProductPurchase(productId: string, purchaseToken: string): Promise<ProductPurchase>;
  acknowledge(productId: string, purchaseToken: string): Promise<void>;
}

/** Google Play Developer API with service-account OAuth (JWT bearer grant), no SDK dependency. */
export class GooglePlayClient implements PlayApi {
  readonly configured = true;
  private token: { value: string; expiresAt: number } | null = null;

  constructor(
    private readonly packageName: string,
    private readonly key: ServiceAccountKey,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}

  private async accessToken(): Promise<string> {
    if (this.token && this.token.expiresAt > Date.now() + 60_000) return this.token.value;
    const tokenUri = this.key.token_uri ?? 'https://oauth2.googleapis.com/token';
    const assertion = await new SignJWT({ scope: SCOPE })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(this.key.client_email)
      .setAudience(tokenUri)
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(await importPKCS8(this.key.private_key, 'RS256'));
    const res = await this.fetchImpl(tokenUri, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) throw new ProviderError('Google OAuth token request failed', res.status);
    const data = (await res.json()) as { access_token: string; expires_in: number };
    this.token = { value: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
    return data.access_token;
  }

  private productUrl(productId: string, purchaseToken: string): string {
    return `${API}/${encodeURIComponent(this.packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
  }

  async getProductPurchase(productId: string, purchaseToken: string): Promise<ProductPurchase> {
    const res = await this.fetchImpl(this.productUrl(productId, purchaseToken), {
      headers: { Authorization: `Bearer ${await this.accessToken()}` },
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) throw new ProviderError('Play purchases.products.get failed', res.status);
    return (await res.json()) as ProductPurchase;
  }

  async acknowledge(productId: string, purchaseToken: string): Promise<void> {
    const res = await this.fetchImpl(`${this.productUrl(productId, purchaseToken)}:acknowledge`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${await this.accessToken()}`,
        'Content-Type': 'application/json',
      },
      body: '{}',
      signal: AbortSignal.timeout(15_000),
    });
    if (!res.ok) throw new ProviderError('Play acknowledge failed', res.status);
  }
}

export class UnconfiguredPlayApi implements PlayApi {
  readonly configured = false;
  async getProductPurchase(): Promise<ProductPurchase> {
    throw new ProviderError('Google Play is not configured');
  }
  async acknowledge(): Promise<void> {
    throw new ProviderError('Google Play is not configured');
  }
}

export const PLAY_API = Symbol('PLAY_API');
