// Drizzle table definitions mirroring supabase/migrations (the schema source of truth).
// Only the tables and columns the API uses are declared.
import { boolean, jsonb, pgEnum, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';
import type { PlanId, SubscriptionStatus } from '@mirthmix/plans';

export const planIdEnum = pgEnum('plan_id', ['free', 'premium']);
export const paymentProvider = pgEnum('payment_provider', ['google_play', 'paddle', 'dodo']);
export const subscriptionStatusEnum = pgEnum('subscription_status', [
  'trialing',
  'active',
  'grace_period',
  'on_hold',
  'paused',
  'canceled',
  'expired',
  'refunded',
]);
export const webhookStatus = pgEnum('webhook_status', [
  'received',
  'processed',
  'ignored',
  'failed',
]);
export type PaymentProviderId = (typeof paymentProvider.enumValues)[number];

const ts = (name: string) => timestamp(name, { withTimezone: true, mode: 'date' });

export const featureFlags = pgTable('feature_flags', {
  key: text('key').primaryKey(),
  enabled: boolean('enabled').notNull(),
});

export const profiles = pgTable('profiles', {
  id: uuid('id').primaryKey(),
  deletionRequestedAt: ts('deletion_requested_at'),
  billingAccountRef: text('billing_account_ref'),
  createdAt: ts('created_at').notNull().defaultNow(),
  updatedAt: ts('updated_at').notNull().defaultNow(),
});

export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull(),
  provider: paymentProvider('provider').notNull(),
  providerSubscriptionId: text('provider_subscription_id').notNull(),
  providerCustomerId: text('provider_customer_id'),
  productId: text('product_id').notNull(),
  planId: planIdEnum('plan_id').$type<PlanId>().notNull(),
  status: subscriptionStatusEnum('status').$type<SubscriptionStatus>().notNull(),
  currentPeriodStart: ts('current_period_start'),
  currentPeriodEnd: ts('current_period_end'),
  cancelAtPeriodEnd: boolean('cancel_at_period_end').notNull().default(false),
  lastEventAt: ts('last_event_at').notNull(),
  providerAccountRef: text('provider_account_ref'),
  linkedProviderSubscriptionId: text('linked_provider_subscription_id'),
  billingInterval: text('billing_interval').$type<'monthly' | 'annual' | 'one_time'>(),
  createdAt: ts('created_at').notNull().defaultNow(),
  updatedAt: ts('updated_at').notNull().defaultNow(),
});

export const webhookEvents = pgTable('webhook_events', {
  id: uuid('id').primaryKey().defaultRandom(),
  provider: paymentProvider('provider').notNull(),
  eventId: text('event_id').notNull(),
  eventType: text('event_type').notNull(),
  status: webhookStatus('status').notNull().default('received'),
  error: text('error'),
  payload: jsonb('payload'),
  receivedAt: ts('received_at').notNull().defaultNow(),
  processedAt: ts('processed_at'),
});

export type SubscriptionRow = typeof subscriptions.$inferSelect;
