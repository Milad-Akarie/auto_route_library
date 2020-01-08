import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route/transitions_builders.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';

import 'screens/login_screen.dart';

@AutoRouter()
class $Router {
  @MaterialRoute(initial: true, fullscreenDialog: true, maintainState: true)
  HomeScreen homeScreenRoute;

  @CupertinoRoute(fullscreenDialog: true, maintainState: true)
  SecondScreen secondScreenRoute;

  @CustomRoute(transitionsBuilder: TransitionsBuilders.fadeIn, durationInMilliseconds: 200)
  LoginScreen loginScreenDialog;
}
