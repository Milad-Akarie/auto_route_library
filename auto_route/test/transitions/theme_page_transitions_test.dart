import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as flutter;
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
  // The pages are built with package:material_ui. The reporter's app, per the
  // first comment on the issue, has its MaterialApp from
  // package:flutter/material.dart, whose Theme is a different class: its
  // builder ran 0 times before the pages read the Theme of either library.
  for (final (label, type) in [
    ('RouteType.material()', const RouteType.material()),
    ('RouteType.adaptive()', const RouteType.adaptive()),
  ]) {
    testWidgets(
      'A page of $label uses the Theme pageTransitionsTheme',
      (tester) async {
        final builder = _RecordingTransitionsBuilder();
        final router = RootStackRouter.build(
          defaultRouteType: type,
          routes: [
            AutoRoute(page: _HomeRoute.page, path: '/'),
            AutoRoute(page: _DetailsRoute.page, path: '/details'),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  for (final platform in TargetPlatform.values)
                    platform: builder,
                },
              ),
            ),
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        builder.calls = 0;

        unawaited(router.push(const _DetailsRoute()));
        await tester.pumpAndSettle();

        expect(find.text('Details'), findsOneWidget);
        expect(builder.calls, greaterThan(0));
      },
      // an adaptive route has no transition on web
      skip: kIsWeb && type is AdaptiveRouteType,
    );
  }

  for (final (label, type) in [
    ('RouteType.material()', const RouteType.material()),
    ('RouteType.adaptive()', const RouteType.adaptive()),
  ]) {
    testWidgets(
      'A page of $label uses the pageTransitionsTheme of a MaterialApp from Flutter',
      (tester) async {
        final builder = _FlutterRecordingTransitionsBuilder();
        final router = RootStackRouter.build(
          defaultRouteType: type,
          routes: [
            AutoRoute(page: _HomeRoute.flutterPage, path: '/'),
            AutoRoute(page: _DetailsRoute.flutterPage, path: '/details'),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          flutter.MaterialApp.router(
            theme: flutter.ThemeData(
              pageTransitionsTheme: flutter.PageTransitionsTheme(
                builders: {
                  for (final platform in TargetPlatform.values)
                    platform: builder,
                },
              ),
            ),
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        builder.calls = 0;

        unawaited(router.push(const _DetailsRoute()));
        // the page is added a frame or two after the push
        for (var i = 0; i < 3 && find.text('Details').evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 100));

        // the theme's builder sets the duration, 200 ms, so the page is still
        // on its way in after 100 ms and is in by 250 ms, before the default
        // 300 ms
        expect(find.text('Details'), findsOneWidget);
        expect(builder.calls, greaterThan(0));
        final route = flutter.ModalRoute.of(
          tester.element(find.text('Details')),
        )!;
        expect(route.transitionDuration, const Duration(milliseconds: 200));
        expect(route.animation!.isCompleted, isFalse);
        await tester.pump(const Duration(milliseconds: 150));
        expect(route.animation!.isCompleted, isTrue);
      },
      // an adaptive route has no transition on web
      skip: kIsWeb && type is AdaptiveRouteType,
    );
  }

  testWidgets(
    'A page uses the nearer Theme when both Material libraries have one',
    (tester) async {
      final builder = _RecordingTransitionsBuilder();
      final flutterBuilder = _FlutterRecordingTransitionsBuilder();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _HomeRoute.page, path: '/'),
          AutoRoute(page: _DetailsRoute.page, path: '/details'),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        flutter.Theme(
          data: flutter.ThemeData(
            pageTransitionsTheme: flutter.PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: flutterBuilder,
              },
            ),
          ),
          child: MaterialApp.router(
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  for (final platform in TargetPlatform.values)
                    platform: builder,
                },
              ),
            ),
            routerConfig: router.config(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      builder.calls = 0;
      flutterBuilder.calls = 0;

      unawaited(router.push(const _DetailsRoute()));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(builder.calls, greaterThan(0));
      expect(flutterBuilder.calls, 0);
    },
  );

  // A page of package:material_ui pushed over a page takes nothing from it:
  // both routes share the delegated transition of material_ui's theme.
  testWidgets(
    'A page keeps its own transition under a MaterialPageRoute of material_ui',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [AutoRoute(page: _HomeRoute.page, path: '/')],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.config()),
      );
      await tester.pumpAndSettle();

      router.navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Pageless')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pageless'), findsOneWidget);
      final homeRoute = ModalRoute.of(
        tester.element(find.text('Home', skipOffstage: false)),
      )!;
      expect(homeRoute.receivedTransition, isNull);
    },
  );

  testWidgets(
    'A widget pushed with pushWidget uses the pageTransitionsTheme of a MaterialApp from Flutter',
    (tester) async {
      final builder = _FlutterRecordingTransitionsBuilder();
      final router = RootStackRouter.build(
        routes: [AutoRoute(page: _HomeRoute.flutterPage, path: '/')],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        flutter.MaterialApp.router(
          theme: flutter.ThemeData(
            pageTransitionsTheme: flutter.PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values) platform: builder,
              },
            ),
          ),
          routerConfig: router.config(),
        ),
      );
      await tester.pumpAndSettle();
      builder.calls = 0;

      unawaited(
        router.pushWidget(const flutter.Scaffold(body: Text('Pushed widget'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pushed widget'), findsOneWidget);
      expect(builder.calls, greaterThan(0));
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

abstract final class _HomeRoute {
  static const String name = 'HomeRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
  static final PageInfo flutterPage = PageInfo(
    name,
    builder: (_) => const flutter.Scaffold(body: Text('Home')),
  );
}

class _DetailsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'DetailsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Details')),
  );
  static final PageInfo flutterPage = PageInfo(
    name,
    builder: (_) => const flutter.Scaffold(body: Text('Details')),
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
