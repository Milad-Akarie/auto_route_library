//ignore_for_file: public_member_api_docs
import 'package:example/web_demo/services/auth_service.dart';
import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  final EdgeInsets padding;

  const LogoutButton({super.key, this.padding = const EdgeInsets.symmetric(vertical: 16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ElevatedButton(
        onPressed: () {
          AuthService.instance.logout();
        },
        child: Text('Logout'),
      ),
    );
  }
}
