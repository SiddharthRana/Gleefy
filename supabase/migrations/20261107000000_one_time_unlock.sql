-- Premium becomes a one-time unlock (Google Play one-time product, Dodo one-time payment) instead
-- of a monthly or annual subscription. Purchases keep using the subscriptions table: a one-time
-- unlock is a row with billing_interval 'one_time', status 'active' and no period end, until it is
-- 'refunded'. provider_subscription_id holds the Play purchase token or the Dodo payment id.

alter table public.subscriptions drop constraint if exists subscriptions_billing_interval_check;
alter table public.subscriptions add constraint subscriptions_billing_interval_check
  check (billing_interval in ('monthly', 'annual', 'one_time'));

comment on table public.subscriptions is
  'Purchases that grant a plan: one-time unlocks (billing_interval one_time) and, historically, subscriptions. Written only by the API from verified store/provider events.';

update public.feature_flags
  set description = 'Enable the Premium one-time unlock and its entitlements'
  where key = 'billing';
