import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Guard for https://github.com/Milad-Akarie/auto_route_library/issues/2065
// Setup, as in the report (auto_route 9.2.0): adaptive routes by default; a
// home router holding a feed router, which starts on a feed listing page
// with a drawer and an AutoLeadingButton in its app bar, and holds a feed
// details page; a comments page beside the feed, as a fullscreen dialog.
// Steps: show the app, then rebuild the MaterialApp with another theme,
// then another locale, then with a new key, as apps do on a setting change.
// Happened: after the rebuild the app bar showed a back button instead of
// the drawer icon.
// Should: the drawer icon shows every time, and there's no back button.
// Already works on dev. The report doesn't show how its MaterialApp was
// built, so these are the common ways a theme or locale change rebuilds it.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.adaptive(),
      routes: [
        AutoRoute(page: _emptyRouter('HomeEmptyRoute'), path: '/', children: [
          AutoRoute(page: _emptyRouter('FeedEmptyRoute'), path: '', initial: true, children: [
            AutoRoute(page: _feedListing, path: '', initial: true),
            AutoRoute(page: _text('FeedDetailsRoute'), path: 'details'),
          ]),
          AutoRoute(page: _text('CommentsRoute'), path: 'comments', fullscreenDialog: true),
        ]),
      ],
    );
  });

  void expectDrawerIcon() {
    expect(find.text('FeedListingRoute'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  }

  testWidgets('AutoLeadingButton should keep the drawer icon when the MaterialApp rebuilds', (tester) async {
    Future<void> pumpApp({Key? key, Brightness brightness = Brightness.light, Locale? locale}) async {
      await tester.pumpWidget(MaterialApp.router(
        key: key,
        theme: ThemeData(brightness: brightness),
        locale: locale,
        routerConfig: router.config(),
      ));
      await tester.pumpAndSettle();
    }

    await pumpApp();
    expectDrawerIcon();

    await pumpApp(brightness: Brightness.dark);
    expectDrawerIcon();

    await pumpApp(brightness: Brightness.dark, locale: const Locale('fr'));
    expectDrawerIcon();

    await pumpApp(key: const ValueKey('fr'), locale: const Locale('fr'));
    expectDrawerIcon();
    expect(router.stack.map((page) => page.name), ['HomeEmptyRoute']);
  });
}

PageInfo _emptyRouter(String name) => PageInfo(name, builder: (_) => const AutoRouter());

PageInfo _text(String name) => PageInfo(name, builder: (_) => Scaffold(body: Text(name)));

final _feedListing = PageInfo(
  'FeedListingRoute',
  builder: (_) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    drawer: const Drawer(),
    body: const Text('FeedListingRoute'),
  ),
);
