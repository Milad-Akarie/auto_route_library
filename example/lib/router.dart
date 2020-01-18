import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route/transitions_builders.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';

@AutoRouter(generateNavigator: false, generateRouteList: false)
class $Router {
  @MaterialRoute(initial: true, fullscreenDialog: true, maintainState: true)
  HomeScreen homeScreenRoute;
  SecondScreen secondScreenRoute;

  @CustomRoute(
    transitionsBuilder: TransitionsBuilders.fadeIn,
    durationInMilliseconds: 100,
    opaque: true,
    barrierDismissible: true,
  )
  LoginScreen loginScreenDialog;
}
