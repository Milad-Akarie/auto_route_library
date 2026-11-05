import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

final _disposed = <String>[];

void main() {
  late RootStackRouter router;
  setUp(() {
    _disposed.clear();
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _ARoute.page, path: '/', initial: true),
        AutoRoute(
          page: _shellPage,
          path: '/b',
          children: [
            AutoRoute(page: _tracked('B1'), path: '', initial: true),
            AutoRoute(page: _tracked('B2'), path: 'two'),
          ],
        ),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1044
  // Open A, then the shell B holding B1 and B2. From inside B, call
  // pushAndPopUntil(A, predicate: (_) => false). Reported: nothing was pushed
  // or popped, and the widgets of the pages that should go were not disposed.
  // Should: only A is on the stack and B1 and B2 are disposed. A new page with
  // the key of a page it replaces in the same update takes over its route (see
  // AutoRoutePage), so the first A keeps its state instead of being disposed.
  testWidgets(
    'pushAndPopUntil with a predicate that keeps nothing disposes the nested pages it removes',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router.push(_ShellRoute(children: [_tracked2('B1'), _tracked2('B2')])),
      );
      await tester.pumpAndSettle();
      expect(find.text('B2'), findsOneWidget);
      _disposed.clear();
      final nested = router.innerRouterOf<StackRouter>(_kShellName)!;

      unawaited(
        nested.pushAndPopUntil(const _ARoute(), predicate: (_) => false),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.stack.map((m) => m.name), [_ARoute.name]);
      expect(find.text('A'), findsOneWidget);
      expect(_disposed, unorderedEquals(['B1', 'B2']));
    },
  );

  // The reporter's second combination, popUntilRouteWithName then push, should
  // end the same way: the pages above the named one are disposed.
  // Not in Chrome's headless runner: it keeps no browser history, so the pop
  // and the push each report the url another way in one frame and Flutter's
  // Router asserts. pop_until_then_push_web_test.dart runs it on real history.
  testWidgets(
    'popUntilRouteWithName then push of the same route disposes the pages above it',
    skip: kIsWeb,
    (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router.push(_ShellRoute(children: [_tracked2('B1'), _tracked2('B2')])),
      );
      await tester.pumpAndSettle();
      _disposed.clear();

      router.popUntilRouteWithName(_ARoute.name);
      unawaited(router.push(const _ARoute()));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      // The first test's A is disposed after its teardown, so it can land here.
      expect(
        _disposed.where((label) => label != 'A'),
        unorderedEquals(['B1', 'B2']),
      );
    },
  );
}

const _kShellName = 'ShellRoute';

PageInfo _tracked(String name) => .new(name, builder: (_) => _Tracked(name));

PageRouteInfo _tracked2(String name) => .new(name);

final PageInfo _shellPage = PageInfo(
  _kShellName,
  builder: (_) => const AutoRouter(),
);

class _ShellRoute extends PageRouteInfo<void> {
  const new({required List<PageRouteInfo> children})
    : super(_kShellName, initialChildren: children);
}

class _ARoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'ARoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const _Tracked('A'),
  );
}

class _Tracked extends StatefulWidget {
  const new(this.label);
  final String label;

  @override
  State<_Tracked> createState() => _TrackedState();
}

class _TrackedState extends State<_Tracked> {
  @override
  void dispose() {
    _disposed.add(widget.label);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}
