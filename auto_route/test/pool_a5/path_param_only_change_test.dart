import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _quiz() => .new('QuizRoute', builder: (data) => Text('Quiz ${data.inheritedPathParams.getString('id')}'));

// https://github.com/Milad-Akarie/auto_route_library/issues/1112
// Steps: under /quiz, a nested route ':id' shows quiz 1. Go to quiz 2, which
// differs only by its path param, with push, navigate, replace, popAndPush
// and replaceNamed-like navigation by path.
// Reported: nothing happens.
// Should: the page for quiz 2 shows.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/quiz',
          page: PageInfo('QuizHostRoute', builder: (_) => const AutoRouter()),
          children: [AutoRoute(path: ':id', page: _quiz())],
        ),
      ],
    );
  });

  PageRouteInfo quiz(String id) => .new(
    'QuizHostRoute',
    initialChildren: [
      PageRouteInfo('QuizRoute', rawPathParams: {'id': id}),
    ],
  );

  final ways = <String, Future<void> Function(String id)>{
    'push': (id) => router.push(quiz(id)),
    'navigate': (id) => router.navigate(quiz(id)),
    'replace': (id) => router.replace(quiz(id)),
    'popAndPush': (id) => router.popAndPush(quiz(id)),
    'navigatePath': (id) => router.navigatePath('/quiz/$id'),
    'pushPath': (id) => router.pushPath('/quiz/$id'),
  };

  for (final MapEntry(key: name, value: go) in ways.entries) {
    testWidgets('$name to the same route with another path param shows the new page', (tester) async {
      await pumpRouterApp(tester, router, initialLink: '/quiz/1');
      expect(find.text('Quiz 1'), findsOneWidget);

      unawaited(go('2'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Quiz 2'), findsOneWidget);
    });
  }
}
