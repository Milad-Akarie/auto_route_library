//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:example/web_demo/widgets/logout_button.dart';
import 'package:example/web_demo/widgets/router_app_bar.dart';
import 'package:flutter/material.dart';

@RoutePage()
class UserPostsPage extends StatefulWidget {
  final int id;

  const UserPostsPage({@PathParam.inherit('userID') required this.id});

  @override
  _UserPostsPageState createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'User Posts ${widget.id}',
              style: TextStyle(fontSize: 30),
            ),
            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    useRootNavigator: true,
                    builder: (_) => AlertDialog(
                      title: Text('Alert'),
                    ),
                  );
                },
                child: Text('Show Dialog')),
            LogoutButton(),
            Expanded(
              child: AutoRouter(),
            )
          ],
        ),
      ),
    );
  }
}
