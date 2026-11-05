import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Pages use the pageTransitionsTheme of the Theme of either Material library.
// https://github.com/Milad-Akarie/auto_route_library/issues/2340
// Headless test: auto_route/test/transitions/theme_page_transitions_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: show the router in a MaterialApp whose theme has its own page
  // transitions builder for every platform, then push a second page.
  // Should: the builder of the theme runs for the pushed page.
  testWidgets('A pushed page uses the Theme pageTransitionsTheme', (
    tester,
  ) async {
    final builder = _RecordingTransitionsBuilder();
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(page: _DetailsRoute.page, path: '/details'),
      ],
    );
    await pumpRouterApp(
      tester,
      router,
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values) platform: builder,
          },
        ),
      ),
    );
    builder.calls = 0;

    unawaited(router.push(const _DetailsRoute()));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(builder.calls, greaterThan(0));
  });

  // Steps: show the router in a MaterialApp from package:flutter/material.dart,
  // whose Theme is another class than material_ui's, with its own page
  // transitions builder for every platform, then push a second page.
  // Should: the builder of that theme runs and sets the page's duration.
  testWidgets(
    'A pushed page uses the pageTransitionsTheme of a MaterialApp from Flutter',
    (tester) async {
      final builder = _FlutterRecordingTransitionsBuilder();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _HomeRoute.page, path: '/'),
          AutoRoute(page: _DetailsRoute.page, path: '/details'),
        ],
      );
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      await tester.pumpWidget(
        flutter.MaterialApp.router(
          theme: flutter.ThemeData(
            pageTransitionsTheme: flutter.PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values) platform: builder,
              },
            ),
          ),
          routerConfig: router.config(
            deepLinkBuilder: (_) => DeepLink.defaultPath,
          ),
        ),
      );
      await tester.pumpAndSettle();
      builder.calls = 0;

      unawaited(router.push(const _DetailsRoute()));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(builder.calls, greaterThan(0));
      final route = flutter.ModalRoute.of(
        tester.element(find.text('Details')),
      )!;
      expect(route.transitionDuration, const Duration(milliseconds: 200));
    },
  );
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
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
}

class _DetailsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'DetailsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Details')),
  );
}

class _FlutterRecordingTransitionsBuilder
    extends flutter.PageTransitionsBuilder {
  int calls = 0;

  @override
  Duration get transitionDuration => const .new(milliseconds: 200);

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
