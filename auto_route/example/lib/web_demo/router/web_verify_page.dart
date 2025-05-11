import 'package:auto_route/auto_route.dart';
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
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              App.of(context).authService.isVerified = true;
            },
            child: Text('verify'),
          ),
        ),
      ),
    );
  }
}
