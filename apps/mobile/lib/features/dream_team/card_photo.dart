import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A card's photo, or its first letter when it has none (or the file is gone).
class CardPhoto extends StatelessWidget {
  const CardPhoto({super.key, required this.path, required this.name, this.size = 40, this.radius});

  final String? path;
  final String name;
  final double size;

  /// Corner radius; a circle by default.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final palette = GfPalette.of(context);
    final theme = Theme.of(context);
    final r = BorderRadius.circular(radius ?? size / 2);
    final letter = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.surfaceMuted, borderRadius: r),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.42, color: theme.colorScheme.primary),
      ),
    );
    if (path == null) return ExcludeSemantics(child: letter);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: r,
        child: Image.file(
          File(path!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, _, _) => letter,
        ),
      ),
    );
  }
}
