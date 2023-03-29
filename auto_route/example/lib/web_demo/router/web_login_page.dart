import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/material.dart';

@RoutePage()
class WebLoginPage extends StatelessWidget {
 final NavigationResolver? resolver;
  final bool showBackButton;
  const WebLoginPage({Key? key, this.resolver, this.showBackButton = true})
      : super(key: key);

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
              App.of(context).authService.isAuthenticated = true;
              if(resolver != null) {
                resolver!.next(true);
              }else{
                context.pushRoute(MainWebRoute());
              }
            },
            child: Text('Login'),
          ),
        ),
      ),
    );
  }
}
