import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: _HomeRoute.page, initial: true),
        AutoRoute(
          path: '/shell',
          page: _ShellRoute.page,
          children: [AutoRoute(path: 'details', page: _DetailsRoute.page)],
        ),
      ],
    );
  });

  // https://github.com/flutter/flutter/issues/146315
  // The home page, outside the shell, awaits push<String> of the details page,
  // a child of a shell that only wraps its children. The details page pops
  // itself with a value. The await must complete with that value.
  for (final (how, push) in [
    (
      'push(DetailsRoute())',
      (StackRouter root) => root.push<String>(const _DetailsRoute()),
    ),
    (
      "pushPath('/shell/details')",
      (StackRouter root) => root.pushPath<String>('/shell/details'),
    ),
  ]) {
    testWidgets(
      'A shell child pushed from outside the shell with $how returns its pop '
      'value',
      (tester) async {
        await pumpRouterConfigApp(tester, router.config());
        String? result;
        var isCompleted = false;
        unawaited(
          push(router).then((value) {
            result = value;
            isCompleted = true;
          }),
        );
        await tester.pumpAndSettle();
        expect(find.text('Details'), findsOneWidget);
        expect(router.stack.map((page) => page.name), [
          'HomeRoute',
          'ShellRoute',
        ]);

        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(isCompleted, isTrue);
        expect(result, 'from details');
      },
    );
  }
}

abstract final class _HomeRoute {
  static const String name = 'HomeRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text('Home')),
  );
}

abstract final class _ShellRoute {
  static const String name = 'ShellRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Shell')),
      body: const AutoRouter(),
    ),
  );
}

class _DetailsRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'DetailsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Column(
        children: [
          const Text('Details'),
          ElevatedButton(
            onPressed: () => context.maybePop('from details'),
            child: const Text('Go back'),
          ),
        ],
      ),
    ),
  );
}
