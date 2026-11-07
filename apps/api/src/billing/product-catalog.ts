import { Inject, Injectable } from '@nestjs/common';
import type { PlanId } from '@mirthmix/plans';
import { ENV, type Env } from '../config/env';
import type { PaymentProviderId } from '../database/schema';
import type { BillingInterval } from './billing.types';

export interface CatalogEntry {
  provider: PaymentProviderId;
  productId: string;
  planId: PlanId;
  interval: BillingInterval;
}

/**
 * Maps provider product/price ids (configured per environment) to MirthMix plans. Prices themselves
 * live in the provider dashboards; this mapping is the only place a provider id becomes a plan.
 */
@Injectable()
export class ProductCatalog {
  readonly entries: CatalogEntry[];

  constructor(@Inject(ENV) env: Env) {
    // Premium is one product per channel, bought once: a Dodo one-time product and a Google Play
    // one-time (non-consumable) in-app product.
    const raw: [PaymentProviderId, string | undefined, PlanId, BillingInterval][] = [
      ['dodo', env.DODO_PRODUCT_PREMIUM, 'premium', 'one_time'],
      ['google_play', env.GOOGLE_PLAY_PRODUCT_ID, 'premium', 'one_time'],
    ];
    this.entries = raw
      .filter((r): r is [PaymentProviderId, string, PlanId, BillingInterval] => Boolean(r[1]))
      .map(([provider, productId, planId, interval]) => ({
        provider,
        productId,
        planId,
        interval,
      }));
  }

  find(provider: PaymentProviderId, productId: string): CatalogEntry | undefined {
    return this.entries.find((e) => e.provider === provider && e.productId === productId);
  }

  forPlan(provider: PaymentProviderId, planId: PlanId): CatalogEntry | undefined {
    return this.entries.find((e) => e.provider === provider && e.planId === planId);
  }
}
