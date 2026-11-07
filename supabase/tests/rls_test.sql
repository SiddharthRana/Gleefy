-- Verifies row level security. Runs after migrations; any failed assertion aborts with an error.
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');

do $$ begin
  assert (select count(*) from public.profiles) = 2, 'profile trigger should create a profile per user';
end $$;

insert into public.subscriptions (user_id, provider, provider_subscription_id, product_id, plan_id, status, last_event_at) values
  ('00000000-0000-0000-0000-00000000000a', 'google_play', 'tok-a', 'gleefy_premium', 'premium', 'active', now()),
  ('00000000-0000-0000-0000-00000000000b', 'paddle', 'sub-b', 'pri_x', 'premium', 'active', now());
insert into public.webhook_events (provider, event_id, event_type) values ('paddle', 'evt_1', 'subscription.created');

-- Act as user A.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', true);

do $$ begin
  assert (select count(*) from public.profiles) = 1, 'user A must only see their own profile';
  assert (select count(*) from public.subscriptions) = 1, 'user A must only see their own subscriptions';
  assert (select count(*) from public.feature_flags) = 0, 'feature flags are not readable by users';
  assert (select count(*) from public.webhook_events) = 0, 'webhook events are not readable by users';
end $$;

-- Users cannot grant themselves a subscription (API only).
do $$ begin
  begin
    insert into public.subscriptions (user_id, provider, provider_subscription_id, product_id, plan_id, status, last_event_at)
      values ('00000000-0000-0000-0000-00000000000a', 'paddle', 'forged', 'x', 'premium', 'active', now());
    raise exception 'insert into subscriptions should have been rejected by RLS';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Users cannot extend or reactivate a subscription.
do $$ declare n int; begin
  update public.subscriptions set status = 'active', current_period_end = now() + interval '10 years';
  get diagnostics n = row_count;
  assert n = 0, 'users must not be able to update subscriptions';
end $$;

-- Users cannot change their billing account reference or switch on billing.
do $$ declare n int; begin
  update public.profiles set billing_account_ref = 'forged';
  get diagnostics n = row_count;
  assert n = 0, 'users must not be able to update profiles';
  update public.feature_flags set enabled = true;
  get diagnostics n = row_count;
  assert n = 0, 'users must not be able to change feature flags';
end $$;

-- Anonymous visitors see nothing.
reset role;
set local role anon;
do $$ begin
  assert (select count(*) from public.profiles) = 0, 'anon must not see profiles';
  assert (select count(*) from public.subscriptions) = 0, 'anon must not see subscriptions';
end $$;

rollback;
