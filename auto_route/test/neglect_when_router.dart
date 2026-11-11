import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// The app of neglect_when_test.dart and web/neglect_when_web_test.dart.

/// A router with Home at '/', Checkout at '/checkout' and Done at '/done'.
RootStackRouter neglectingRouter() => .build(
  routes: [
    AutoRoute(page: _page('Home'), path: '/', initial: true),
    AutoRoute(page: _page('Checkout'), path: '/checkout'),
    AutoRoute(page: _page('Done'), path: '/done'),
  ],
);

/// The config of [router] with the README's `neglectWhen`, which keeps urls
/// under '/checkout' from being reported.
RouterConfig<UrlState> neglectingConfig(RootStackRouter router) =>
    router.config(
      neglectWhen: (location) => location?.startsWith('/checkout') ?? false,
    );

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
