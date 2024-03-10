//ignore_for_file: public_member_api_docs
import 'package:example/web_demo/router/app_navigator_observer.dart';
import 'package:example/web_demo/router/app_router.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final _authService = AuthService.instance;
    final _appRouter = AppRouter(authService: _authService);

    return MaterialApp.router(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter.config(
        reevaluateListenable: _authService,
        navigatorObservers: () => [
          AppNavigatorObserver(appRouter: _appRouter),
        ],
      ),
    );
  }
}
