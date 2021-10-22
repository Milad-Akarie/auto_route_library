import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_router.dart';

class AuthGuard extends AutoRouteGuard {
  final FirebaseAuth firebaseAuth;

  AuthGuard(this.firebaseAuth) {
    firebaseAuth.authStateChanges().listen((User? user) {
      print('Auth Changed $user');
    });
  }

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (firebaseAuth.currentUser != null) resolver.next();

    final authResult = await router.push(const LoginRoute());
    router.removeLast();
    print(authResult);
    if (authResult == true) {
      resolver.next();
    }
  }
}
