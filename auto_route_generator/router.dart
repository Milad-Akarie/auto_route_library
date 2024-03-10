// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i2;
import 'package:auto_route_generator/playground/index_2.dart' as _i3;
import 'package:auto_route_generator/playground/test_page.dart' as _i1;
import 'package:vertex_auth/vertex_auth.dart' as _i4;

abstract class $AstRouterTest extends _i2.RootStackRouter {
  $AstRouterTest({super.navigatorKey});

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    TestPage.name: (routeData) {
      final args = routeData.argsAs<TestPageArgs>();
      return _i2.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.TestPage(
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
    required _i3.Generice<_i3.DemoModel> model,
    _i4.AuthState? state,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          TestPage.name,
          args: TestPageArgs(
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
    required this.model,
    this.state,
  });

  final _i3.Generice<_i3.DemoModel> model;

  final _i4.AuthState? state;

  @override
  String toString() {
    return 'TestPageArgs{model: $model, state: $state}';
  }
}
