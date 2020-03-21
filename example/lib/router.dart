import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:example/screens/second_screen.dart';

export 'package:auto_route/auto_route.dart';
export 'router.gr.dart';
import 'main.dart';

@MaterialAutoRouter()
class $Router {
  @initial
  HomeScreen homeScreen;
  @GuardedBy([AuthGuard])
  SecondScreen secondScreen;
  LoginScreen loginScreen;
}
