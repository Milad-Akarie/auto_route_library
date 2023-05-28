import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage()
class WebVerifyPage extends StatelessWidget {
  final ValueChanged<bool>? onResult;

  const WebVerifyPage({Key? key, this.onResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // onWillPop: () {
      //   onLoginResult?.call(false);
      //   return SynchronousFuture(true);
      // },
      child: Scaffold(
        appBar: AppBar(
            // automaticallyImplyLeading: showBackButton,
            // title: Text('Login to continue'),
            ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // print('root has Guards: ${context.router.activeGuardObserver.guardInProgress}' );
              // print('nested has guards: ${context.router.innerRouterOf<StackRouter>(UserRoute.name)?.activeGuardObserver.guardInProgress}' );
              App.of(context).authService.isVerified = true;
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
