import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

// AutoLeadingButton keeps the drawer icon when the MaterialApp rebuilds.
// https://github.com/Milad-Akarie/auto_route_library/issues/2065
// Headless test: auto_route/test/leading_button_drawer_test.dart
//
// Setup, as in the report: adaptive routes by default; a home router
// holding a feed router, which starts on a feed listing page with a drawer
// and an AutoLeadingButton in its app bar.
// Steps: show the app, then rebuild the MaterialApp with another
// theme, another locale, then a new key.
// Reported: after the rebuild the app bar showed a back button.
// Should: the drawer icon shows every time.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AutoLeadingButton keeps the drawer icon when the MaterialApp rebuilds',
    (tester) async {
      final router = RootStackRouter.build(
        defaultRouteType: const RouteType.adaptive(),
        routes: [
          AutoRoute(
            page: _emptyRouter('HomeEmptyRoute'),
            path: '/',
            children: [
              AutoRoute(
                page: _emptyRouter('FeedEmptyRoute'),
                path: '',
                initial: true,
                children: [
                  AutoRoute(page: _feedListing, path: '', initial: true),
                  AutoRoute(page: _text('FeedDetailsRoute'), path: 'details'),
                ],
              ),
              AutoRoute(
                page: _text('CommentsRoute'),
                path: 'comments',
                fullscreenDialog: true,
              ),
            ],
          ),
        ],
      );

      Future<void> pumpApp({
        Key? key,
        Brightness brightness = .light,
        Locale? locale,
      }) async {
        await tester.pumpWidget(
          MaterialApp.router(
            key: key,
            theme: ThemeData(brightness: brightness),
            locale: locale,
            routerConfig: router.config(
              deepLinkBuilder: (link) =>
                  link.initial ? DeepLink.defaultPath : link,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      void expectDrawerIcon() {
        expect(find.text('FeedListingRoute'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
      }

      await pumpApp();
      expectDrawerIcon();
      await pumpApp(brightness: .dark);
      expectDrawerIcon();
      await pumpApp(brightness: .dark, locale: const Locale('fr'));
      expectDrawerIcon();
      await pumpApp(key: const ValueKey('fr'), locale: const Locale('fr'));
      expectDrawerIcon();
    },
  );
}

PageInfo _emptyRouter(String name) =>
    .new(name, builder: (_) => const AutoRouter());

PageInfo _text(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

final _feedListing = PageInfo(
  'FeedListingRoute',
  builder: (_) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    drawer: const Drawer(),
    body: const Text('FeedListingRoute'),
  ),
);
