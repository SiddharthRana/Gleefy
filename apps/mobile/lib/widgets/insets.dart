import 'package:flutter/widgets.dart';

/// Padding for a screen's scrolling list that also clears the system navigation bar. A ListView
/// with its own padding doesn't add the bar's height, so on Android's edge-to-edge screens the last
/// items stayed hidden behind the bar and couldn't be scrolled into view.
EdgeInsets listPadding(BuildContext context, EdgeInsets padding) =>
    padding.copyWith(bottom: padding.bottom + MediaQuery.paddingOf(context).bottom);
