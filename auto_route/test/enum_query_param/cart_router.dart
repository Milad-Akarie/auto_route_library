import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

part 'cart_router.gr.dart';

enum MfUserCartTypes { rm, mf }

@AutoRouterConfig(replaceInRouteName: 'View,Route', generateForDir: ['test/enum_query_param'])
class CartRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: CartHomeRoute.page),
    AutoRoute(path: '/cart', page: MfUserCartRoute.page),
  ];
}

@RoutePage()
class CartHomeView extends StatelessWidget {
  const CartHomeView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

@RoutePage()
class MfUserCartView extends StatelessWidget {
  const MfUserCartView({super.key, @QueryParam('type') required this.userCartType});

  final MfUserCartTypes? userCartType;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text('Cart ${userCartType?.name ?? 'null'}'));
}
