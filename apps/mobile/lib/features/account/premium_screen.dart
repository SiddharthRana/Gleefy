import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../account/entitlement.dart';
import '../../billing/billing_controller.dart';
import '../../content/content.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../telemetry/analytics.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/motion.dart';
import 'purchase_status_card.dart';
import '../modes.dart';
import '../../widgets/insets.dart';

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
      final bought = ref.watch(billingControllerProvider.select((b) => b.phase == PurchasePhase.success));
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The celebration stays up after a purchase turns Premium on.
          if (bought) ...[
            PurchaseStatusCard(state: ref.watch(billingControllerProvider)),
            const SizedBox(height: MmSpace.s4),
          ],
          _ActiveStatus(entitlement: entitlement),
        ],
      );
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
            data: (c) => c.playAvailable ? _Offer(productId: c.productId) : _Message(l.premiumUnavailableNow),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _Message(l.premiumUnavailableNow),
          );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(MmSpace.s4)),
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
    final purchase = entitlement.account?.purchases.where((p) => !p.pending).firstOrNull;
    final bought = purchase?.purchasedAt;
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
        if (purchase != null && bought != null) ...[
          const SizedBox(height: MmSpace.s2),
          Text(l.premiumBoughtOn(formatDay(context, bought), purchase.isWeb ? l.premiumStoreWeb : l.premiumStorePlay)),
        ],
      ],
    );
  }
}

/// The Google Play purchase: the price button, then an animated card with the result.
class _Offer extends ConsumerStatefulWidget {
  const _Offer({required this.productId});
  final String productId;

  @override
  ConsumerState<_Offer> createState() => _OfferState();
}

class _OfferState extends ConsumerState<_Offer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final phase = ref.read(billingControllerProvider).phase;
      if (phase == PurchasePhase.idle || phase == PurchasePhase.error) {
        unawaited(ref.read(billingControllerProvider.notifier).load(widget.productId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final billing = ref.watch(billingControllerProvider);
    final controller = ref.read(billingControllerProvider.notifier);
    final offer = billing.offer;
    final busy = switch (billing.phase) {
      PurchasePhase.loading || PurchasePhase.purchasing || PurchasePhase.pending || PurchasePhase.verifying => true,
      _ => false,
    };
    final showCard = switch (billing.phase) {
      PurchasePhase.idle || PurchasePhase.loading || PurchasePhase.ready => false,
      _ => true,
    };
    final pendingPurchase = ref.watch(entitlementProvider).account?.purchases.any((p) => p.pending) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingPurchase && !showCard) ...[
          Text(l.premiumPaymentPending, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MmSpace.s3),
        ],
        if (offer != null && billing.phase != PurchasePhase.success) ...[
          Pressable(
            enabled: !busy,
            child: FilledButton(
              onPressed: busy ? null : () => controller.buy(offer),
              child: Text(l.premiumUnlock(offer.price)),
            ),
          ),
          const SizedBox(height: MmSpace.s2),
          Text(l.premiumOnce, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: MmSpace.s3),
        ],
        if (billing.phase == PurchasePhase.loading)
          const Padding(padding: EdgeInsets.all(MmSpace.s2), child: LinearProgressIndicator()),
        if (showCard) ...[
          PurchaseStatusCard(state: billing, onRetry: () => unawaited(controller.retry(widget.productId))),
          const SizedBox(height: MmSpace.s2),
        ],
        if (billing.phase != PurchasePhase.success)
          TextButton(onPressed: busy ? null : controller.restore, child: Text(l.premiumRestore)),
      ],
    );
  }
}
