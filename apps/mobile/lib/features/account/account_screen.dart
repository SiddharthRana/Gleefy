import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/entitlement.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/insets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (_) => const _DeleteDialog());
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(entitlementProvider.notifier).deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(l.accountDeleted)));
      if (context.mounted) context.go('/');
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l.accountDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final entitlement = ref.watch(entitlementProvider);
    final premium = ref.watch(premiumProvider);
    if (!entitlement.signedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(l.accountTitle)),
        body: Padding(
          padding: const EdgeInsets.all(MmSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.premiumSignInPrompt),
              const SizedBox(height: MmSpace.s4),
              FilledButton(onPressed: () => context.push('/account/sign-in'), child: Text(l.premiumSignIn)),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.symmetric(vertical: MmSpace.s4)),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(l.accountSignedInAs(entitlement.user?.email ?? '')),
          ),
          ListTile(
            leading: Icon(premium ? Icons.verified_rounded : Icons.lock_outline_rounded),
            title: Text(premium ? l.premiumActive : l.premiumTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/premium'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(l.accountSignOut),
            onTap: () async {
              await ref.read(entitlementProvider.notifier).signOut();
              if (context.mounted) context.pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            title: Text(l.accountDelete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  // The dialog owns its controller so it outlives the closing animation.
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.accountDelete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.accountDeleteBody),
          const SizedBox(height: MmSpace.s3),
          TextField(
            controller: _confirm,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'DELETE', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        TextButton(
          onPressed: _confirm.text.trim() == 'DELETE' ? () => Navigator.pop(context, true) : null,
          child: Text(l.accountDeleteConfirm),
        ),
      ],
    );
  }
}
