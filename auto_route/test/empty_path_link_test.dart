import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'router_test_utils.dart';
import 'simple_router/router.dart';
import 'universal_link_test.dart' show sendPlatformLink;

// flutter/flutter#132044: a link with no path, such as
// myapp://com.example.app, threw while the app was in the background, where the reporter wanted the
// app brought to the front where it was.
// Open FirstRoute, push SecondRoute, then send myapp://com.example.app from
// the platform. It opens '/', as a link to myapp://com.example.app/ does, with
// no error. An app that wants to stay where it is answers such a link with
// DeepLink.none from its deepLinkBuilder.
void main() {
  testWidgets('A link with no path opens the first page without an error', (tester) async {
    final router = SimpleRouter();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();

    expect(await sendPlatformLink(tester, 'myapp://com.example.app'), isTrue);
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, FirstRoute.name);
  });

  testWidgets('A deepLinkBuilder can keep the page for a link with no path', (tester) async {
    final router = SimpleRouter();
    await pumpRouterConfigApp(
      tester,
      router.config(deepLinkBuilder: (link) => !link.initial && link.uri.path.isEmpty ? DeepLink.none : link),
    );
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();

    await sendPlatformLink(tester, 'myapp://com.example.app');
    expect(tester.takeException(), isNull);
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
  });
}
