import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

void main() {
  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.
  RootStackRouter buildRouter() => RootStackRouter.build(
    routes: [
      AutoRoute(path: '/', page: page('HomeRoute'), initial: true),
      AutoRoute(path: '/manufacturers', page: _ManufacturersByLetterRoute.page),
      AutoRoute(path: '/book/:id', page: _BookRoute.page),
    ],
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2098
  // Push a page whose route has a required argument that isn't a path or
  // query param, then let the platform end and restore the app. The
  // argument is an object of the app, which state restoration can't save,
  // so the page can't come back; the app should come back without it,
  // not fail with "ManufacturersByLetterRouteArgs can not be null".
  testWidgets('a page whose required argument was not saved is left out on restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(_ManufacturersByLetterRoute(letter: const _Letter('M')));
    await tester.pumpAndSettle();
    expect(find.text('Manufacturers by M'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(RestorableRouterApp.router.stack.map((page) => page.name), ['HomeRoute']);
  }, skip: kIsWeb);

  // The reporter found that query params work. A page that takes its value
  // from a path param comes back with it.
  testWidgets('a page that takes its value from a path param comes back', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    RestorableRouterApp.router.push(_BookRoute(id: 7));
    await tester.pumpAndSettle();
    expect(find.text('Book 7'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(find.text('Book 7'), findsOneWidget);
    expect(RestorableRouterApp.router.stack.map((page) => page.name), ['HomeRoute', 'BookRoute']);
  }, skip: kIsWeb);
}

class _Letter {
  const _Letter(this.value);

  final String value;
}

// As the generator writes a route whose page takes a required argument.
class _ManufacturersByLetterRouteArgs {
  const _ManufacturersByLetterRouteArgs({required this.letter});

  final _Letter letter;
}

class _ManufacturersByLetterRoute extends PageRouteInfo<_ManufacturersByLetterRouteArgs> {
  _ManufacturersByLetterRoute({required _Letter letter})
    : super(name, args: _ManufacturersByLetterRouteArgs(letter: letter));

  static const name = 'ManufacturersByLetterRoute';

  static final page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_ManufacturersByLetterRouteArgs>();
      return Text('Manufacturers by ${args.letter.value}');
    },
  );
}

// As the generator writes a route whose page takes a @PathParam.
class _BookRouteArgs {
  const _BookRouteArgs({required this.id});

  final int id;
}

class _BookRoute extends PageRouteInfo<_BookRouteArgs> {
  _BookRoute({required int id})
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
      final args = data.argsAs<_BookRouteArgs>(orElse: () => _BookRouteArgs(id: pathParams.getInt('id')));
      return Text('Book ${args.id}');
    },
  );
}
