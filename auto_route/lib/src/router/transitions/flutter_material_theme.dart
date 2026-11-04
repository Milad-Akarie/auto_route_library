import 'package:flutter/cupertino.dart' as flutter show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart'
    as flutter
    show PageTransitionsBuilder, Theme, ThemeData, ZoomPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

/// The theme of package:flutter/material.dart above [context], when it is
/// nearer than the [Theme] of package:material_ui; null otherwise.
///
/// auto_route builds its pages with package:material_ui, whose [Theme] is a
/// different class from Flutter's own. An app on Flutter's `MaterialApp` puts
/// only Flutter's in the tree, so [Theme.of] gives its pages the fallback
/// theme and none of the app's page transitions. When this returns null, the
/// nearest Material theme is material_ui's, or there is none, and [Theme.of]
/// applies as before.
///
/// When it returns a theme, [context] depends on it, so it rebuilds when that
/// theme changes.
flutter.ThemeData? flutterMaterialThemeOf(BuildContext context) {
  var flutterThemeIsNearer = false;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is flutter.Theme) {
      flutterThemeIsNearer = true;
      return false;
    }
    return widget is! Theme;
  });
  return flutterThemeIsNearer ? flutter.Theme.of(context) : null;
}

/// The page transitions builder of [theme] for its platform, or Flutter's
/// default for that platform when [theme] names none, the way Flutter's
/// `MaterialPageRoute` picks it.
flutter.PageTransitionsBuilder flutterPageTransitionsBuilderOf(flutter.ThemeData theme) {
  return theme.pageTransitionsTheme.builders[theme.platform] ??
      switch (theme.platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => const flutter.CupertinoPageTransitionsBuilder(),
        TargetPlatform.android ||
        TargetPlatform.fuchsia ||
        TargetPlatform.windows ||
        TargetPlatform.linux => const flutter.ZoomPageTransitionsBuilder(),
      };
}
