//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '404!',
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}