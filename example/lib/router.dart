import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route/transitions_builders.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';

@AutoRouter(generateNavigator: true, generateRouteList: true)
class $Router {
  @MaterialRoute(initial: true)
  HomeScreen homeScreenRoute;

  // @CupertinoRoute(name: 'custom_cupertino/name')
  // SecondScreen secondScreenRoute;

  // @CustomRoute(name: 'custom_route_name')
  // LoginScreen loginScreenDialog;
}
