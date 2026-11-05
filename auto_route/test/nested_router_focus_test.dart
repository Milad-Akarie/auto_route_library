import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'no_op.dart';
import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/112367: rebuilding a nested
  // Navigator whose pages are new objects each build took focus from a text
  // field outside it, and gave it back to the field that last had focus
  // inside it.
  // Steps: HostRoute shows an outer TextField above a nested AutoRouter whose
  // page is an inner TextField. Tap the inner field, then the outer one, then
  // rebuild HostRoute, as a MediaQuery change does.
  // Should: the outer field keeps focus. auto_route hands the nested
  // Navigator the same page objects on a rebuild, so it has nothing to update.
  testWidgets('Rebuilding a nested router keeps focus in a field outside it', (
    tester,
  ) async {
    late StateSetter setHostState;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return const Scaffold(
                  body: Column(
                    children: [
                      TextField(key: Key('outer')),
                      Expanded(child: AutoRouter()),
                    ],
                  ),
                );
              },
            ),
          ),
          children: [
            AutoRoute(
              path: '',
              page: PageInfo(
                'InnerRoute',
                builder: (_) => const TextField(key: Key('inner')),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    await tester.tap(find.byKey(const Key('inner')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('outer')));
    await tester.pump();
    final outerFocus = FocusManager.instance.primaryFocus;
    expect(
      outerFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key,
      const Key('outer'),
    );

    setHostState(noOp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(outerFocus));
  });

  // https://github.com/flutter/flutter/issues/94249: with a nested
  // Navigator, after the user focused a field on its page and tapped outside to
  // close the keyboard, pushing the next page in the nested Navigator opened
  // the keyboard and closed it again at once.
  // Steps: HostRoute's nested AutoRouter shows a page with a TextField. Tap
  // the field, tap outside it, where HostRoute unfocuses its focus scope,
  // then push the next page in the nested router.
  // Should: the push neither shows nor hides the keyboard.
  testWidgets(
    'Pushing in a nested router after closing the keyboard does not open it '
    'again',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HostRoute',
              builder: (_) => Builder(
                builder: (context) => Scaffold(
                  body: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: const Column(
                      children: [
                        SizedBox(height: 100, child: Text('outside')),
                        Expanded(child: AutoRouter()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  'FirstStepRoute',
                  builder: (_) => const TextField(key: Key('first step')),
                ),
              ),
              AutoRoute(
                path: 'next',
                page: PageInfo(
                  'NextStepRoute',
                  builder: (_) => const TextField(key: Key('next step')),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      await tester.tap(find.byKey(const Key('first step')));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.text('outside'));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);

      tester.testTextInput.log.clear();
      unawaited(
        router.innerRouterOf<StackRouter>('HostRoute')!.pushPath('/next'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('next step')), findsOneWidget);
      expect(
        tester.testTextInput.log.map((call) => call.method),
        isNot(anyOf(contains('TextInput.show'), contains('TextInput.hide'))),
      );
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );
}
