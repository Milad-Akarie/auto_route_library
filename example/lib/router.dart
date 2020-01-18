import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';

@AutoRouter(generateNavigator: true, generateRouteList: false)
class $Router {
  @MaterialRoute(initial: true)
  HomeScreen homeScreenRoute;

  @CupertinoRoute(name: '/custom_cupertino_name')
  SecondScreen secondScreenRoute;

  @CustomRoute(name: '/custom_route_name')
  LoginScreen loginScreenDialog;
}
