import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../widgets/mode_tile.dart';
import '../widgets/motion.dart';
import 'modes.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).libraryTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(MmSpace.s4),
        itemCount: LibraryEntry.values.length,
        separatorBuilder: (_, _) => const SizedBox(height: MmSpace.s3),
        itemBuilder: (_, i) => StaggerIn(
          index: i,
          child: ModeTile(entry: LibraryEntry.values[i]),
        ),
      ),
    );
  }
}
