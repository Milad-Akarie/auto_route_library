//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.gr.dart';
import 'package:example/web_demo/widgets/logout_button.dart';
import 'package:flutter/material.dart';

@RoutePage()
class UserProfilePage extends StatefulWidget {
  final VoidCallback? navigate;
  final int likes;
  final int userId;

  const UserProfilePage({
    Key? key,
    this.navigate,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Profile : ${widget.userId}  likes: ${widget.likes}',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '${context.routeData.queryParams}',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 16),
            MaterialButton(
              color: Colors.red,
              onPressed: widget.navigate ??
                  () {
                    context.pushRoute(UserFavoritePostsRoute());
                  },
              child: Text('Posts -> '),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _counter++;
                  });
                },
                child: Text('State $_counter'),
              ),
            ),
            LogoutButton(),
          ],
        ),
      ),
    );
  }
}
