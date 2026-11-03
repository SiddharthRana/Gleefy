import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../account/api_client.dart';
import '../../account/entitlement.dart';
import '../../billing/billing_controller.dart';
import '../../billing/billing_gateway.dart';
import '../../config/app_config.dart';
import '../../content/content.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../telemetry/analytics.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../modes.dart';

String formatDay(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(d.toLocal());

/// What Premium includes, its status, and (on Android) the Google Play purchase.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    // Always re-check with the server when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track('premium_viewed', {'premium': ref.read(premiumProvider)});
      unawaited(ref.read(entitlementProvider.notifier).refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final entitlement = ref.watch(entitlementProvider);
    final premium = ref.watch(premiumProvider);
    final api = ref.watch(accountApiProvider);
    final content = ref.watch(contentProvider);

    Widget status;
    if (premium) {
      status = _ActiveStatus(entitlement: entitlement);
    } else if (!api.configured || !ref.watch(authRepositoryProvider).configured) {
      status = _Message(l.premiumUnavailableBuild);
    } else if (!entitlement.signedIn) {
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.premiumSignInPrompt, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MmSpace.s4),
          FilledButton(onPressed: () => context.push('/account/sign-in'), child: Text(l.premiumSignIn)),
        ],
      );
    } else {
      status = ref
          .watch(billingConfigProvider)
          .when(
            data: (c) =>
                c.playAvailable ? _Offers(subscriptionId: c.subscriptionId) : _Message(l.premiumUnavailableNow),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _Message(l.premiumUnavailableNow),
          );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.all(MmSpace.s4),
        children: [
          Text(l.premiumPitch, style: theme.textTheme.titleMedium),
          const SizedBox(height: MmSpace.s4),
          Card(
            child: Padding(padding: const EdgeInsets.all(MmSpace.s4), child: status),
          ),
          if (entitlement.signedIn) ...[
            const SizedBox(height: MmSpace.s2),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(l.accountTitle),
              subtitle: Text(l.accountSignedInAs(entitlement.user?.email ?? '')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/account'),
            ),
          ],
          const SizedBox(height: MmSpace.s6),
          Semantics(header: true, child: Text(l.premiumIncludes, style: theme.textTheme.titleMedium)),
          const SizedBox(height: MmSpace.s2),
          for (final mode in GameMode.values)
            for (final c in content.packFor(mode).categories.where((c) => c.tier == Tier.premium))
              ListTile(
                leading: Icon(premium ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: palette.textMuted),
                title: Text(c.name),
                subtitle: Text(
                  '${modeName(l, mode)} · ${l.setupQuestionsAvailable(content.packFor(mode).countIn([c.id]))}',
                ),
              ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodyLarge);
}

class _ActiveStatus extends ConsumerWidget {
  const _ActiveStatus({required this.entitlement});
  final EntitlementState entitlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final until = entitlement.snapshot?.validUntil;
    final subs = entitlement.account?.subscriptions ?? const <SubscriptionInfo>[];
    final granting = subs.where((s) => s.currentPeriodEnd == until).firstOrNull ?? subs.firstOrNull;
    final config = ref.watch(billingConfigProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: MmSpace.s2),
            Expanded(child: Text(l.premiumActive, style: theme.textTheme.titleLarge)),
          ],
        ),
        if (until != null) ...[
          const SizedBox(height: MmSpace.s2),
          Text(
            entitlement.offline
                ? l.premiumOffline(formatDay(context, until.add(offlineGrace)))
                : granting?.cancelAtPeriodEnd == true
                ? l.premiumEndsOn(formatDay(context, until))
                : l.premiumPaidThrough(formatDay(context, until)),
          ),
        ],
        if (granting != null) ...[
          const SizedBox(height: MmSpace.s3),
          if (granting.isWeb)
            Text(l.premiumManageWeb)
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l.premiumManagePlay),
              onPressed: () => launchUrl(
                Uri.https('play.google.com', '/store/account/subscriptions', {
                  if (config != null && config.subscriptionId.isNotEmpty) 'sku': config.subscriptionId,
                  'package': AppConfig.packageName,
                }),
                mode: LaunchMode.externalApplication,
              ),
            ),
        ],
      ],
    );
  }
}

class _Offers extends ConsumerStatefulWidget {
  const _Offers({required this.subscriptionId});
  final String subscriptionId;

  @override
  ConsumerState<_Offers> createState() => _OffersState();
}

class _OffersState extends ConsumerState<_Offers> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final phase = ref.read(billingControllerProvider).phase;
      if (phase == PurchasePhase.idle || phase == PurchasePhase.error) {
        unawaited(ref.read(billingControllerProvider.notifier).load(widget.subscriptionId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final billing = ref.watch(billingControllerProvider);
    final controller = ref.read(billingControllerProvider.notifier);
    final busy = switch (billing.phase) {
      PurchasePhase.loading || PurchasePhase.purchasing || PurchasePhase.pending || PurchasePhase.verifying => true,
      _ => false,
    };
    final message = switch (billing.phase) {
      PurchasePhase.pending => l.premiumPending,
      PurchasePhase.verifying => l.premiumVerifying,
      PurchasePhase.success => l.premiumSuccess,
      PurchasePhase.error => switch (billing.error) {
        'store_unavailable' => l.premiumErrorStore,
        'account_mismatch' => l.premiumErrorMismatch,
        'verify_failed' => l.premiumErrorVerify,
        'network' => l.premiumErrorNetwork,
        _ => l.premiumErrorPurchase,
      },
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final offer in billing.offers) ...[
          FilledButton(
            onPressed: busy ? null : () => controller.buy(offer),
            child: Text(
              offer.interval == StoreInterval.annual ? l.premiumPerYear(offer.price) : l.premiumPerMonth(offer.price),
            ),
          ),
          const SizedBox(height: MmSpace.s2),
        ],
        if (busy) const Padding(padding: EdgeInsets.all(MmSpace.s2), child: LinearProgressIndicator()),
        if (message != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: MmSpace.s2),
              child: Text(message),
            ),
          ),
        if (billing.duplicateWarning) Text(l.premiumDuplicate),
        TextButton(onPressed: busy ? null : controller.restore, child: Text(l.premiumRestore)),
      ],
    );
  }
}
