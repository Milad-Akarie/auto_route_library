import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';

part 'picker_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'View,Route',
  generateForDir: ['integration_test/support/picker_router'],
)
class PickerRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: PickerHomeRoute.page),
    AutoRoute(path: '/picker', page: PickerRoute.page),
  ];
}

@RoutePage()
class PickerHomeView extends StatelessWidget {
  const PickerHomeView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

/// A page that lists [items] of any type and pops with the one tapped, the
/// kind of page #2050 asks to route to.
@RoutePage()
class PickerView<T> extends StatelessWidget {
  const PickerView({
    super.key,
    this.items = const [],
    @QueryParam() this.title = 'Pick',
  });

  final List<T> items;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('$title from ${items.length}'),
        for (final item in items)
          TextButton(
            onPressed: () => context.router.maybePop<T>(item),
            child: Text('Item $item'),
          ),
      ],
    ),
  );
}
