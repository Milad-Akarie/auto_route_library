import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';

part 'list_router.gr.dart';

enum Sort { asc, desc }

@AutoRouterConfig(replaceInRouteName: 'View,Route', generateForDir: ['test/list_query_param'])
class ListRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: ListHomeRoute.page),
    AutoRoute(path: '/items', page: ItemsRoute.page),
    AutoRoute(path: '/tags', page: TagsRoute.page),
  ];
}

@RoutePage()
class ListHomeView extends StatelessWidget {
  const ListHomeView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

// A page whose query params are lists, as in upstream issue 2061.
@RoutePage()
class ItemsView extends StatelessWidget {
  const ItemsView({
    super.key,
    @QueryParam() this.ids,
    @QueryParam() this.prices,
    @QueryParam() this.flags,
    @QueryParam() this.sorts,
    @QueryParam() this.picked = const [1, 2],
  });

  final List<int>? ids;
  final List<double>? prices;
  final List<bool>? flags;
  final List<Sort>? sorts;
  final List<int> picked;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Text(
      'ids ${ids ?? 'null'} prices ${prices ?? 'null'} flags ${flags ?? 'null'} sorts ${sorts?.map((s) => s.name).toList() ?? 'null'} picked $picked',
    ),
  );
}

// A page whose query params are a Set and an Iterable, as in
// flutter/flutter#108437.
@RoutePage()
class TagsView extends StatelessWidget {
  const TagsView({super.key, @QueryParam() this.tags = const {}, @QueryParam() this.ids, @QueryParam() this.sorts});

  final Set<String> tags;
  final Iterable<int>? ids;
  final Set<Sort>? sorts;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Text('tags $tags ids ${ids?.toList() ?? 'null'} sorts ${sorts?.map((s) => s.name).toList() ?? 'null'}'),
  );
}
