import { Module } from '@nestjs/common';
import { ENV, type Env } from '../config/env';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';
import { WEB_PAYMENT_PROVIDER, type WebPaymentProvider } from './billing.types';
import {
  GooglePlayClient,
  parseServiceAccount,
  PLAY_API,
  UnconfiguredPlayApi,
} from './google-play/play-client';
import { googleOidcKeys, RTDN_KEY_RESOLVER } from './google-play/rtdn-verifier';
import { ProductCatalog } from './product-catalog';
import { DodoProvider } from './providers/dodo.provider';
import { SubscriptionStore } from './subscription-store';
import { WebhookLedger } from './webhook-ledger';

@Module({
  controllers: [BillingController],
  providers: [
    BillingService,
    ProductCatalog,
    SubscriptionStore,
    WebhookLedger,
    {
      provide: WEB_PAYMENT_PROVIDER,
      inject: [ENV, ProductCatalog],
      useFactory: (env: Env, catalog: ProductCatalog): WebPaymentProvider | null => {
        if (env.WEB_PAYMENT_PROVIDER === 'dodo') {
          return new DodoProvider(
            { apiKey: env.DODO_API_KEY, webhookSecret: env.DODO_WEBHOOK_SECRET, env: env.DODO_ENV },
            catalog,
          );
        }
        return null;
      },
    },
    {
      provide: PLAY_API,
      inject: [ENV],
      useFactory: (env: Env) =>
        env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
          ? new GooglePlayClient(
              env.GOOGLE_PLAY_PACKAGE_NAME,
              parseServiceAccount(env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON),
            )
          : new UnconfiguredPlayApi(),
    },
    { provide: RTDN_KEY_RESOLVER, useFactory: googleOidcKeys },
  ],
})
export class BillingModule {}
