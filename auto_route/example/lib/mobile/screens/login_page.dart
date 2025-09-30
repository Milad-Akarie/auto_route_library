import 'package:auto_route/annotations.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//ignore_for_file: public_member_api_docs
@RoutePage()
class LoginPage extends StatelessWidget {
  final bool showBackButton;

  const LoginPage({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login page'),
        automaticallyImplyLeading: showBackButton,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<AuthService>().login();
          },
          child: Text('Login'),
        ),
      ),
    );
  }
}
