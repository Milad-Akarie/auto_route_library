//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.gr.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/material.dart';

@RoutePage()
class VerifyPage extends StatelessWidget {
  final ValueChanged<bool>? onResult;

  const VerifyPage({Key? key, this.onResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // onWillPop: () {
      //   onLoginResult?.call(false);
      //   return SynchronousFuture(true);
      // },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login to continue'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              print('root has Guards: ${context.router.activeGuardObserver.guardInProgress}');
              print(
                  'nested has guards: ${context.router.innerRouterOf<StackRouter>(UserRoute.name)?.activeGuardObserver.guardInProgress}');
              AuthService.instance.verifyAccount();
              if (onResult != null) {
                onResult!(true);
              } else {
                context.pushRoute(MainWebRoute());
              }
            },
            child: Text('verify'),
          ),
        ),
      ),
    );
  }
}
