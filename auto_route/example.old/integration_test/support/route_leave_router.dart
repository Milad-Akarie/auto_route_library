import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A router with HomeRoute '/', EditorRoute '/editor' and PreviewRoute
/// '/preview'. The editor's content sits in an [AutoRouteLeaveListener] that
/// adds each leave to [leaves], inside a [PopScope] that refuses pops while
/// [editorCanPop] is false.
RootStackRouter buildRouteLeaveRouter({
  required List<RouteLeaveKind> leaves,
  required ValueNotifier<bool> editorCanPop,
}) => .build(
  routes: [
    NamedRouteDef(
      name: 'HomeRoute',
      path: '/',
      builder: (_, _) => _page('Home'),
    ),
    NamedRouteDef(
      name: 'EditorRoute',
      path: '/editor',
      builder: (_, _) => ValueListenableBuilder<bool>(
        valueListenable: editorCanPop,
        builder: (_, canPop, _) => PopScope(
          canPop: canPop,
          child: AutoRouteLeaveListener(
            onLeave: leaves.add,
            child: _page('Editor'),
          ),
        ),
      ),
    ),
    NamedRouteDef(
      name: 'PreviewRoute',
      path: '/preview',
      builder: (_, _) => _page('Preview'),
    ),
  ],
);

Widget _page(String text) => Scaffold(body: SafeArea(child: Text(text)));
