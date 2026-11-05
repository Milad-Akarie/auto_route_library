import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import 'router.dart';

// flutter/flutter#172026: an app widget that rebuilt after its first
// frame, as one under a state management scope does, lost the page the browser was
// refreshed on: the router went back to its first page.
void main() {
  // The app keeps one router and calls router.config() in every build.
  // Navigate to SecondRoute, then rebuild the app: the stack and url stay.
  testWidgets('Rebuilding the app with router.config() keeps the stack', (tester) async {
    final router = SimpleRouter();
    addTearDown(router.dispose);
    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: rebuild,
        builder: (_, _, _) => MaterialApp.router(routerConfig: router.config()),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.navigate(const SecondRoute()));
    await tester.pumpAndSettle();

    rebuild.value++;
    await tester.pumpAndSettle();
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(router.currentUrl, '/second-route');
  });

  // The reporter's app makes a new router in every build, and rebuilds once
  // after its first frame. Open it at /second-route, as a refresh does: the
  // second router opens /second-route too, from the platform's initial route.
  testWidgets('A new router built after the first frame opens the refreshed url', (tester) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    dispatcher.defaultRouteNameTestValue = '/second-route';
    final routers = <SimpleRouter>[];
    addTearDown(() {
      for (final router in routers) {
        router.dispose();
      }
    });
    await tester.pumpWidget(
      _RebuildsAfterFirstFrame(
        builder: () {
          final router = SimpleRouter();
          routers.add(router);
          return MaterialApp.router(routerConfig: router.config());
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(routers, hasLength(2));
    expectCurrentPage(routers.last, SecondRoute.name);
    expect(routers.last.currentUrl, '/second-route');
  });
}

class _RebuildsAfterFirstFrame extends StatefulWidget {
  const _RebuildsAfterFirstFrame({required this.builder});

  final Widget Function() builder;

  @override
  State<_RebuildsAfterFirstFrame> createState() => _RebuildsAfterFirstFrameState();
}

class _RebuildsAfterFirstFrameState extends State<_RebuildsAfterFirstFrame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => (context as Element).markNeedsBuild());
  }

  @override
  Widget build(BuildContext context) => widget.builder();
}
