//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.gr.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  final ValueChanged<bool>? onResult;

  const LoginPage({Key? key, this.onResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login to continue'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _login(context),
          child: Text('Login'),
        ),
      ),
    );
  }

  void _login(BuildContext context) {
    print('root has Guards: ${context.router.activeGuardObserver.guardInProgress}' );
    print('nested has guards: ${context.router.innerRouterOf<StackRouter>(UserRoute.name)?.activeGuardObserver.guardInProgress}' );

    AuthService.instance.login();

    if (onResult != null) {
      onResult!(true);
    } else {
      context.replaceRoute(MainWebRoute());
    }
  }
}
