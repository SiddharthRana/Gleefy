import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content.dart';
import '../l10n/app_localizations.dart';
import '../state/custom_questions.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'modes.dart';
import '../widgets/insets.dart';

String describeProblem(AppLocalizations l, CustomProblem p, GameMode mode) => switch (p) {
  CustomProblem.empty => l.myQuestionsErrorEmpty,
  CustomProblem.tooLong => l.myQuestionsErrorTooLong(customLimits[mode]!),
  CustomProblem.same => l.myQuestionsErrorSame,
  CustomProblem.duplicate => l.myQuestionsErrorDuplicate,
  CustomProblem.notAllowed => l.myQuestionsErrorNotAllowed,
  CustomProblem.full => l.myQuestionsErrorFull(maxCustomQuestions),
};

/// Write, edit and delete your own two-choice questions. They never leave the phone.
class MyQuestionsScreen extends ConsumerStatefulWidget {
  const MyQuestionsScreen({super.key, this.initialMode = GameMode.wouldYouRather});

  final GameMode initialMode;

  @override
  ConsumerState<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends ConsumerState<MyQuestionsScreen> {
  late GameMode _mode = customLimits.containsKey(widget.initialMode) ? widget.initialMode : GameMode.wouldYouRather;

  Future<void> _openEditor([WyrItem? existing]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _QuestionDialog(mode: _mode, existing: existing),
    );
  }

  void _delete(WyrItem q, int index) {
    final l = AppLocalizations.of(context);
    final c = ref.read(customQuestionsProvider.notifier);
    final mode = _mode;
    c.remove(mode, q.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.myQuestionsDeleted),
          action: SnackBarAction(label: l.playUndo, onPressed: () => c.restore(mode, q, index)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final questions = ref.watch(customQuestionsProvider).of(_mode);
    return Scaffold(
      appBar: AppBar(title: Text(l.myQuestionsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.myQuestionsAdd),
      ),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s4, MmSpace.s4, 96)),
        children: [
          Text(l.myQuestionsIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MmSpace.s1),
          Text(l.myQuestionsHowTo, style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
          const SizedBox(height: MmSpace.s4),
          SegmentedButton<GameMode>(
            segments: [for (final m in customLimits.keys) ButtonSegment(value: m, label: Text(modeName(l, m)))],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: MmSpace.s4),
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: MmSpace.s8),
              child: Text(l.myQuestionsEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ),
          for (final (i, q) in questions.indexed)
            Card(
              child: ListTile(
                title: Text(q.a),
                subtitle: Text(q.b),
                onTap: () => _openEditor(q),
                trailing: IconButton(
                  tooltip: l.myQuestionsDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(q, i),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionDialog extends ConsumerStatefulWidget {
  const _QuestionDialog({required this.mode, this.existing});

  final GameMode mode;
  final WyrItem? existing;

  @override
  ConsumerState<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<_QuestionDialog> {
  // The dialog owns its controllers so they outlive the closing animation.
  late final _a = TextEditingController(text: widget.existing?.a);
  late final _b = TextEditingController(text: widget.existing?.b);
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _save() {
    final c = ref.read(customQuestionsProvider.notifier);
    final existing = widget.existing;
    final problem = existing == null
        ? c.add(widget.mode, _a.text, _b.text)
        : c.edit(widget.mode, existing.id, _a.text, _b.text);
    if (problem == null) {
      Navigator.pop(context);
    } else {
      setState(() => _error = describeProblem(AppLocalizations.of(context), problem, widget.mode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final max = customLimits[widget.mode]!;
    InputDecoration field(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());
    return AlertDialog(
      title: Text(widget.existing == null ? l.myQuestionsAdd : l.myQuestionsEdit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _a,
              autofocus: true,
              maxLength: max,
              textCapitalization: TextCapitalization.sentences,
              decoration: field(l.myQuestionsOptionA),
            ),
            const SizedBox(height: MmSpace.s2),
            TextField(
              controller: _b,
              maxLength: max,
              textCapitalization: TextCapitalization.sentences,
              decoration: field(l.myQuestionsOptionB),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: MmSpace.s2),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
