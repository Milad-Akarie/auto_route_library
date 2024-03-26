// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i2;
import 'package:auto_route_generator/playground/test_page.dart' as _i1;

abstract class $AstRouterTest extends _i2.RootStackRouter {
  $AstRouterTest({super.navigatorKey});

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    TestPage.name: (routeData) {
      final args = routeData.argsAs<TestPageArgs>();
      return _i2.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.TestPage(
          key: args.key,
          model: args.model,
          state: args.state,
        ),
      );
    }
  };
}

/// generated route for
/// [_i1.TestPage]
class TestPage extends _i2.PageRouteInfo<TestPageArgs> {
  TestPage({
    Key? key,
    required Generice<DemoModel> model,
    AuthState? state,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          TestPage.name,
          args: TestPageArgs(
            key: key,
            model: model,
            state: state,
          ),
          initialChildren: children,
        );

  static const String name = 'TestPage';

  static const _i2.PageInfo<TestPageArgs> page = _i2.PageInfo<TestPageArgs>(name);
}

class TestPageArgs {
  const TestPageArgs({
    this.key,
    required this.model,
    this.state,
  });

  final Key? key;

  final Generice<DemoModel> model;

  final AuthState? state;

  @override
  String toString() {
    return 'TestPageArgs{key: $key, model: $model, state: $state}';
  }
}
