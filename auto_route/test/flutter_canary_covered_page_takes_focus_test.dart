import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/99573.
// Setup: HomeRoute shows an autofocus TextField only once `showField` is
// true. SecondRoute, pushed over it, has an autofocus TextField. Plain
// Flutter fails the same way.
// Steps: push SecondRoute, then show HomeRoute's field while SecondRoute
// covers it, as a page under another does when its data reloads.
// Today the covered page's field takes focus from the page on screen: a
// route keeps its subtree mounted and focusable while covered, and Flutter
// lets a route that is not current take focus. Flutter's team weighed
// excluding focus from routes that are not current, but a route would then
// forget its focused field and could not give it back on a pop, so auto_route
// does not wrap covered pages in ExcludeFocus either. An app avoids it by
// checking `ModalRoute.of(context)?.isCurrent` before autofocusing.
// If this test fails after a Flutter upgrade, Flutter keeps focus in the
// current route: drop this canary.
void main() {
  testWidgets('a covered page that builds an autofocus field takes focus from the page on screen', (tester) async {
    final showField = ValueNotifier(false);
    addTearDown(showField.dispose);
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HomeRoute',
            builder: (_) => Scaffold(
              body: ValueListenableBuilder(
                valueListenable: showField,
                builder: (_, show, _) =>
                    show ? const TextField(key: Key('home'), autofocus: true) : const Text('HomeRoute'),
              ),
            ),
          ),
        ),
        AutoRoute(
          path: '/second',
          page: PageInfo(
            'SecondRoute',
            builder: (_) => const Scaffold(body: TextField(key: Key('second'), autofocus: true)),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('SecondRoute')));
    await tester.pumpAndSettle();
    expect(_focusedField(), const Key('second'));

    showField.value = true;
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'SecondRoute');
    expect(_focusedField(), const Key('home'));
  });
}

Key? _focusedField() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.key;
