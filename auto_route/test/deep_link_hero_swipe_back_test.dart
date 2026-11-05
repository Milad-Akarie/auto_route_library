import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/57768
  // Steps, as in the report: the app starts on '/page2' and builds the stack
  // [Page1, Page2] from that link (includePrefixMatches). Both pages hold a
  // Hero with the same tag and transitionOnUserGestures; Page2's Hero is
  // shifted by padding. Swipe back from the left edge on iOS.
  // Should: Page1 shows, with no error. Flutter threw "box.hasSize" from the
  // Hero and "_backGestureController != null" from the route, since Page1 was
  // never laid out.
  testWidgets(
    'Swiping back from a deep link into a page with a Hero returns to the '
    'page below without an error',
    (tester) async {
      final router = RootStackRouter.build(
        defaultRouteType: const RouteType.cupertino(),
        routes: [
          AutoRoute(page: _page1, path: '/'),
          AutoRoute(page: _page2, path: '/page2'),
        ],
      );
      final config = router.config(
        includePrefixMatches: true,
        deepLinkBuilder: (link) =>
            link.initial ? const DeepLink.path('/page2') : link,
      );
      addTearDown(router.dispose);
      addTearDown((config.routerDelegate as AutoRouterDelegate).dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: iosTheme, routerConfig: config),
      );
      await tester.pumpAndSettle();
      expect(router.stack.map((p) => p.name), ['Page1Route', 'Page2Route']);
      expect(find.text('Page 2'), findsOneWidget);

      await swipeBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), ['Page1Route']);
      expect(find.text('Page 1'), findsOneWidget);
    },
  );
}

final _page1 = PageInfo(
  'Page1Route',
  builder: (_) => const _HeroPage('Page 1', .zero),
);

final _page2 = PageInfo(
  'Page2Route',
  builder: (_) => const _HeroPage('Page 2', .only(left: 100)),
);

class _HeroPage extends StatelessWidget {
  const new(this.label, this.padding);

  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: padding,
        child: Hero(
          tag: 'tag',
          transitionOnUserGestures: true,
          child: SizedBox(
            width: 150,
            height: 150,
            child: ColoredBox(color: Colors.red, child: Text(label)),
          ),
        ),
      ),
    ),
  );
}
