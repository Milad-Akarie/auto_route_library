import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage()
class WebLoginPage extends StatelessWidget {
  final ValueChanged<bool>? onResult;

  const WebLoginPage({super.key, this.onResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            App.of(context).authService.isAuthenticated = true;
          },
          child: Text('Login'),
        ),
      ),
    );
  }
}
