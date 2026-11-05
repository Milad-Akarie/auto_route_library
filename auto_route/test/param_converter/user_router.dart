import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

part 'user_router.gr.dart';

/// An id kept in its own class, the kind of value #1794 asks to take from
/// the url.
@immutable
class UserId {
  const new(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is UserId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Reads a [UserId] from `u-` and its digits, and refuses any other text.
class _UserIdConverter extends ParamConverter<UserId> {
  const new();

  @override
  UserId? fromParam(String value) => RegExp(r'^u-\d+$').hasMatch(value) ? .new(value.substring(2)) : null;

  @override
  String toParam(UserId value) => 'u-${value.value}';
}

const _kUserIdConverter = _UserIdConverter();

@AutoRouterConfig(replaceInRouteName: 'View,Route', generateForDir: ['test/param_converter'])
class UserRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: '/', page: UserHomeRoute.page),
    AutoRoute(path: '/user/:id', page: UserProfileRoute.page),
  ];
}

@RoutePage()
class UserHomeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}

@RoutePage()
class UserProfileView extends StatelessWidget {
  const new({
    @PathParam('id', _kUserIdConverter) required this.id,
    super.key,
    @QueryParam('by', _kUserIdConverter) this.by,
  });

  final UserId id;
  final UserId? by;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text('User ${id.value} by ${by?.value ?? 'null'}'));
}
