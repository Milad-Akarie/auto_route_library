import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';

import 'screens/login_screen.dart';

@AutoRouter()
class $Router {
  @MaterialRoute(initial: true)
  HomeScreen homeScreenRoute;

  SecondScreen secondScreenRoute;

  LoginScreen loginScreenDialog;
}
