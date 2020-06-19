
import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/services.dart';

class AuthGuard extends RouteGuard {
  Future<bool> canNavigate(ExtendedNavigatorState navigator, String routeName, Object arguments) async {
//    if (isLoggedIn) {
//      return true;
//    }
////    navigator.pushReplacementNamed(Routes.loginScreen);
//    return true;
    print('guarding $routeName');
//     await Future.delayed(Duration(milliseconds: 100));
    var loggedIn =  await navigator.root.pushNamed<bool>(Routes.loginScreen);
    if(!loggedIn){
       SystemChannels.platform.invokeMethod('SystemNavigator.pop');

    }
    return isLoggedIn;
  }
}

var isLoggedIn = true;
