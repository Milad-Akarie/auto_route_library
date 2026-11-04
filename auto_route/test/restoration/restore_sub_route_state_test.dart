import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: page('HomeRoute'), initial: true),
      AutoRoute(page: _signUpPage),
      AutoRoute(
        page: const EmptyShellRoute('LoginRoute'),
        children: [
          AutoRoute(page: page('LoginFormRoute'), initial: true),
          AutoRoute(page: _signUpPage),
        ],
      ),
    ],
  );

  Future<void> typeAndRestore(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pumpAndSettle();
    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  // flutter/flutter#99315: in go_router, a page opened as a sub route, a
  // sign-up page under a login page, came back after the platform ended and
  // restored the app, but without the text typed in it: its page had no
  // restoration id. Every auto_route page has one.
  // Steps: open LoginRoute, push SignUpRoute in its nested router, type 'Ada'
  // in its field, then let the platform end and restore the app.
  // Should: the sign-up page is back, its field holds 'Ada'.
  testWidgets('a page in a nested router keeps its restorable state', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(RestorableRouterApp.router.push(const NamedRoute('LoginRoute', children: [NamedRoute('SignUpRoute')])));
    await tester.pumpAndSettle();
    await typeAndRestore(tester);
    expect(RestorableRouterApp.router.topMatch.name, 'SignUpRoute');
    expect(find.text('Ada'), findsOneWidget);
  }, skip: kIsWeb);

  // flutter/flutter#99315, the same for the sign-up page pushed on the root
  // router over the home page.
  testWidgets('a pushed page keeps its restorable state', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(RestorableRouterApp.router.push(const NamedRoute('SignUpRoute')));
    await tester.pumpAndSettle();
    await typeAndRestore(tester);
    expect(RestorableRouterApp.router.stack.map((p) => p.name), ['HomeRoute', 'SignUpRoute']);
    expect(find.text('Ada'), findsOneWidget);
  }, skip: kIsWeb);
}

final _signUpPage = PageInfo('SignUpRoute', builder: (_) => const _SignUpPage());

class _SignUpPage extends StatefulWidget {
  const _SignUpPage();

  @override
  State<_SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<_SignUpPage> with RestorationMixin {
  final _name = RestorableTextEditingController();

  @override
  String get restorationId => 'sign_up';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) => registerForRestoration(_name, 'name');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: TextField(controller: _name.value));
}
