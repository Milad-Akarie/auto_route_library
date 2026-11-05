import 'package:auto_route/auto_route.dart';
import 'package:example/declarative/dec_router.gr.dart';

/// Routes of the declarative navigation example.
///
/// One main route holds the three steps (name, age and result) as children.
@AutoRouterConfig(generateForDir: ['lib/declarative'])
class DecRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: MainRoute.page,
      initial: true,
      children: [
        AutoRoute(page: NameInputRoute.page),
        AutoRoute(page: AgeInputRoute.page),
        AutoRoute(page: ResultRoute.page),
      ],
    ),
  ];
}
