import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'path_reader.dart';
import 'router_test_utils.dart';

// #1225: right after a push, context.router.currentPath read in
// didChangeDependencies still gave the path before the push; a timer read
// the new one.
// Steps: the home page holds a widget that watches the router and reads
// currentPath and currentUrl in didChangeDependencies; push '/welcome', by
// path and by route.
// Should: the last read, made when the push makes the widget's dependencies
// change, is '/welcome'.
void main() {
  final pushes = <String, Future<void> Function(StackRouter)>{
    'pushPath': (router) => router.pushPath('/welcome'),
    'push': (router) => router.push(const NamedRoute('WelcomeRoute')),
  };

  for (final MapEntry(key: name, value: push) in pushes.entries) {
    testWidgets('after $name, currentPath read on change is the new path', (
      tester,
    ) async {
      final reads = <String>[];
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => Scaffold(body: PathReader(reads)),
          ),
          NamedRouteDef(
            name: 'WelcomeRoute',
            path: '/welcome',
            builder: (_, _) => const Scaffold(body: Text('Welcome')),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(reads, ['/ /']);

      unawaited(push(router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(reads.length, greaterThan(1));
      expect(reads.lastOrNull, '/welcome /welcome');
    });
  }
}
