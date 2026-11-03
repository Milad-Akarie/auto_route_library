import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2340
  // Reported: since 11.2.0 pages no longer use the transitions of the app's
  // Theme.pageTransitionsTheme, they use the fallback of the Android theme.
  // Setup: a MaterialApp.router whose theme names its own page transitions
  // builder, and a page pushed on top of the first one.
  // Should: the builder of the theme runs for the pushed page.
  //
  // This holds for the app's Theme from package:material_ui, which 11.2.0
  // builds its pages with. An app whose MaterialApp comes from
  // package:flutter/material.dart has a different Theme class that those pages
  // never find, so it keeps the fallback: the reporter's case, per the first
  // comment on the issue.
  for (final (label, type) in [
    ('RouteType.material()', const RouteType.material()),
    ('RouteType.adaptive()', const RouteType.adaptive()),
  ]) {
    testWidgets('A page of $label uses the Theme pageTransitionsTheme', (tester) async {
      final builder = _RecordingTransitionsBuilder();
      final router = RootStackRouter.build(
        defaultRouteType: type,
        routes: [
          AutoRoute(page: _HomeRoute.page, path: '/'),
          AutoRoute(page: _DetailsRoute.page, path: '/details'),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {for (final platform in TargetPlatform.values) platform: builder},
            ),
          ),
          routerConfig: router.config(),
        ),
      );
      await tester.pumpAndSettle();
      builder.calls = 0;

      router.push(const _DetailsRoute());
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(builder.calls, greaterThan(0));
    },
        // an adaptive route has no transition on web
        skip: kIsWeb && type is AdaptiveRouteType);
  }
}

class _RecordingTransitionsBuilder extends PageTransitionsBuilder {
  int calls = 0;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    calls++;
    return child;
  }
}

class _HomeRoute extends PageRouteInfo<void> {
  const _HomeRoute() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Home')));
}

class _DetailsRoute extends PageRouteInfo<void> {
  const _DetailsRoute() : super(name);

  static const String name = 'DetailsRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text('Details')));
}
