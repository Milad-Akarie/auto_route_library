import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// A page whose required argument was not saved is left out on restoration.
// https://github.com/Milad-Akarie/auto_route_library/issues/2098
// Headless test: auto_route/test/restoration/restore_args_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: namedPage('HomeRoute'), initial: true),
      AutoRoute(path: '/manufacturers', page: _ManufacturersByLetterRoute.page),
      AutoRoute(path: '/book/:id', page: _BookRoute.page),
    ],
  );

  // Steps: push a page whose route has a required argument that isn't a
  // path or query param, then restore the app.
  // Should: the app comes back on the home page, without the page whose
  // argument couldn't be saved, and without the error
  // "ManufacturersByLetterRouteArgs can not be null".
  testWidgets(
    'a page whose required argument was not saved is left out on restoration',
    (tester) async {
      await pumpRestorableApp(tester, buildRouter);
      unawaited(
        RestorableRouterApp.router.push(
          _ManufacturersByLetterRoute(letter: const _Letter('M')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manufacturers by M'), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('HomeRoute'), findsOneWidget);
      await expectBrowserUrl('/');
    },
    skip: kIsWeb,
  );

  // Steps: push a page that takes its value from a path param, then
  // restore the app.
  // Should: the page comes back with its value, at '/book/7'.
  testWidgets('a page that takes its value from a path param comes back', (
    tester,
  ) async {
    await pumpRestorableApp(tester, buildRouter);
    unawaited(RestorableRouterApp.router.push(_BookRoute(id: 7)));
    await tester.pumpAndSettle();
    expect(find.text('Book 7'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(find.text('Book 7'), findsOneWidget);
    await expectBrowserUrl('/book/7');
    await systemBack(tester);
    expect(find.text('HomeRoute'), findsOneWidget);
  }, skip: kIsWeb);
}

class _Letter {
  const new(this.value);

  final String value;
}

// As the generator writes a route whose page takes a required argument.
class _ManufacturersByLetterRouteArgs {
  const new({required this.letter});

  final _Letter letter;
}

class _ManufacturersByLetterRoute
    extends PageRouteInfo<_ManufacturersByLetterRouteArgs> {
  new({required _Letter letter})
    : super(name, args: _ManufacturersByLetterRouteArgs(letter: letter));

  static const name = 'ManufacturersByLetterRoute';

  static final page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ManufacturersByLetterRouteArgs>();
      return Scaffold(
        body: Center(child: Text('Manufacturers by ${args.letter.value}')),
      );
    },
  );
}

// As the generator writes a route whose page takes a @PathParam.
class _BookRouteArgs {
  const new({required this.id});

  final int id;
}

class _BookRoute extends PageRouteInfo<_BookRouteArgs> {
  new({required int id})
    : super(
        name,
        args: _BookRouteArgs(id: id),
        rawPathParams: {'id': id},
      );

  static const name = 'BookRoute';

  static final page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<_BookRouteArgs>(
        orElse: () => _BookRouteArgs(id: pathParams.getInt('id')),
      );
      return Scaffold(body: Center(child: Text('Book ${args.id}')));
    },
  );
}
