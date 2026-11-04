import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1806
  // Reported: an AutoLeadingButton can't be tested with a mocked StackRouter.
  // Setup, as reported: a StackRouterScope with a mocked StackRouter whose
  // canPop is stubbed to false, around an AutoLeadingButton. It threw "type
  // 'Null' is not a subtype of type 'PagelessRoutesObserver'", because the
  // button reads the router's pagelessRoutesObserver, and the mock, with
  // nothing stubbed for it, returned null. The first comment adds that the
  // button needs a RouterScope too, and the next one that PagelessRoutesObserver
  // was not exported to build one for the mock.
  // Should: with both scopes, and a PagelessRoutesObserver (now exported from
  // package:auto_route/auto_route.dart) for the mock to return, the button
  // builds, and shows a back button when canPop is true.
  Widget buttonWith(_MockStackRouter router) {
    addTearDown(router.pagelessRoutesObserver.dispose);
    return MaterialApp(
      home: RouterScope(
        controller: router,
        stateHash: 0,
        inheritableObserversBuilder: () => [],
        child: StackRouterScope(
          controller: router,
          stateHash: 0,
          child: const Scaffold(body: AutoLeadingButton()),
        ),
      ),
    );
  }

  testWidgets('An AutoLeadingButton builds with a mocked StackRouter that cannot pop', (tester) async {
    await tester.pumpWidget(buttonWith(_MockStackRouter(canPopValue: false)));

    expect(tester.takeException(), isNull);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('An AutoLeadingButton shows a back button with a mocked StackRouter that can pop', (tester) async {
    final router = _MockStackRouter(canPopValue: true);
    await tester.pumpWidget(buttonWith(router));
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    expect(router.maybePopTopCalls, 1);
  });
}

class _MockStackRouter extends Fake implements StackRouter {
  _MockStackRouter({required this.canPopValue});

  final bool canPopValue;
  int maybePopTopCalls = 0;

  @override
  final PagelessRoutesObserver pagelessRoutesObserver = PagelessRoutesObserver();

  @override
  bool canPop({bool ignoreChildRoutes = false, bool ignoreParentRoutes = false, bool ignorePagelessRoutes = false}) =>
      canPopValue;

  @override
  AutoRoutePage<dynamic>? get topPage => null;

  @override
  Future<bool> maybePopTop<T extends Object?>([T? result]) async {
    maybePopTopCalls++;
    return true;
  }
}
