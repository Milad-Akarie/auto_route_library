import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

// flutter/flutter#145290: with Android's predictive back on, closing a bottom
// sheet shown on the root navigator over a nested stack made the next back
// close the app instead of popping the nested page.
// Steps: on Android, a shell route hosts a nested router. Push Second over
// Home in it, and from Second show a modal bottom sheet on the root
// navigator. Go back, by system back or by the predictive back gesture,
// which closes the sheet, then go back again.
// Should: once the sheet is closed, Flutter still tells Android it handles
// back, and the second back pops Second to Home inside the shell.
void main() {
  final backs = {'system back': systemBack, 'predictive back': predictiveBack};

  for (final MapEntry(key: name, value: back) in backs.entries) {
    testWidgets(
      'after $name closes a root sheet over a nested stack, the app '
      'still takes back',
      (tester) async {
        final recorder = FrameworkHandlesBackRecorder()..listen(tester);
        final router = RootStackRouter.build(
          defaultRouteType: const .material(enablePredictiveBackGesture: true),
          routes: [
            NamedRouteDef(
              name: 'ShellRoute',
              path: '/',
              builder: (_, _) => const Column(
                children: [
                  Expanded(child: AutoRouter()),
                  SizedBox(height: 10),
                ],
              ),
              children: [
                NamedRouteDef(
                  name: 'HomeRoute',
                  path: 'home',
                  initial: true,
                  builder: (_, _) => const Scaffold(body: Text('Home')),
                ),
                NamedRouteDef(
                  name: 'SecondRoute',
                  path: 'second',
                  builder: (_, _) => const Scaffold(body: Text('Second')),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: androidTheme,
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        unawaited(router.navigate(const NamedRoute('SecondRoute')));
        await tester.pumpAndSettle();
        final handlesBack = [recorder.isHandlingBack];

        showModalBottomSheet<void>(
          context: tester.element(find.text('Second')),
          useRootNavigator: true,
          builder: (_) => const SizedBox(height: 100, child: Text('Sheet')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Sheet'), findsOneWidget);

        await back(tester);
        expect(find.text('Sheet'), findsNothing);
        expect(find.text('Second'), findsOneWidget);
        handlesBack.add(recorder.isHandlingBack);
        expect(handlesBack, [true, true]);

        await back(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(
          router
              .innerRouterOf<StackRouter>('ShellRoute')!
              .stack
              .map((page) => page.name),
          ['HomeRoute'],
        );
      },
      skip: kIsWeb,
      // Android only: on web Flutter never tells the platform whether it
      // handles back.
    );
  }
}
