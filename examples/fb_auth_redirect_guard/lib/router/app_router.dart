import 'package:auto_route/auto_route.dart';
import 'package:fb_auth_redirect_guard/router/auth_guard.dart';
import 'package:fb_auth_redirect_guard/screens/home_screen.dart';
import 'package:fb_auth_redirect_guard/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: [
    AutoRoute(
      page: HomeScreen,
      initial: true,
      guards: [AuthGuard],
    ),
    AutoRoute(page: LoginScreen),
  ],
)
class AppRouter extends _$AppRouter {
  AppRouter({
    required FirebaseAuth firebaseAuth,
  }) : super(authGuard: AuthGuard(firebaseAuth));
}
