import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

// https://github.com/flutter/flutter/issues/174935
// Setup: the app and its router restore state. A shell page wraps its nested
// router in a RestorationScope of its own; the page inside the shell keeps a
// counter in a RestorableInt.
// Steps: count up, let the platform end the app, then restore it.
// Should: the counter comes back, as it does for a page outside a shell.
void main() {
  for (final (kind, shell) in [
    ('a stack', () => const AutoRouter()),
    ('tabs', () => const AutoTabsRouter(routes: [NamedRoute('CounterRoute')])),
  ]) {
    for (final userScope in [true, false]) {
      final scope = userScope ? ' wrapped in a RestorationScope' : '';
      testWidgets('A page in $kind$scope gets its restorable state back', (
        tester,
      ) async {
        RootStackRouter buildRouter() => .build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'ShellRoute',
                builder: (_) => userScope
                    ? RestorationScope(
                        restorationId: 'shell_scope',
                        child: shell(),
                      )
                    : shell(),
              ),
              children: [
                AutoRoute(
                  path: '',
                  page: PageInfo(
                    'CounterRoute',
                    builder: (_) => const _CounterPage(),
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(RestorableRouterApp(buildRouter));
        await tester.pumpAndSettle();
        expect(find.text('Count 0'), findsOneWidget);
        await tester.tap(find.text('Count 0'));
        await tester.tap(find.text('Count 0'));
        await tester.pumpAndSettle();
        expect(find.text('Count 2'), findsOneWidget);

        await tester.restartAndRestore();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text('Count 2'),
          findsOneWidget,
          reason: 'after tester.restartAndRestore()',
        );
      }, skip: kIsWeb);
    }
  }
}

class _CounterPage extends StatefulWidget {
  const new();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> with RestorationMixin {
  final _count = RestorableInt(0);

  @override
  String get restorationId => 'counter_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) =>
      registerForRestoration(_count, 'count');

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count.value++),
      child: Text('Count ${_count.value}'),
    );
  }
}
