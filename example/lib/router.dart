import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route/transitions_builders.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';

import 'screens/login_screen.dart';

@autoRouter
class $Router {
  @initial
  HomeScreen homeScreenRoute;

  SecondScreen secondScreenRoute;

  @CustomRoute(
    transitionsBuilder: TransitionsBuilders.slideBottom,
    durationInMilliseconds: 400,
    barrierDismissible: true,
  )
  LoginScreen loginScreenDialog;
}
