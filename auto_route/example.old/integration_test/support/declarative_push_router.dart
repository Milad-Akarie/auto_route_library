import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A router whose HostRoute page builds AutoRouter.declarative with ARoute;
/// BRoute is one of its routes the list never holds.
RootStackRouter buildDeclarativePushRouter() => .build(
  routes: [
    NamedRouteDef(
      name: 'HostRoute',
      path: '/',
      builder: (_, _) => AutoRouter.declarative(routes: (_) => [const NamedRoute('ARoute')]),
      children: [
        NamedRouteDef(name: 'ARoute', path: '', builder: (_, _) => _page('A')),
        NamedRouteDef(name: 'BRoute', path: 'b', builder: (_, _) => _page('B')),
      ],
    ),
  ],
);

Widget _page(String text) => Scaffold(body: SafeArea(child: Text(text)));
