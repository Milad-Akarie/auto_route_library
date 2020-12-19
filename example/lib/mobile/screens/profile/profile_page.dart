import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserData userData;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profile page',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 32),
            RaisedButton(
                child: Text('My Books'),
                onPressed: () {
                  context.router.push(MyBooksRoute(filter: 'FromRoute'));
                }),
            const SizedBox(height: 32),
            userData == null
                ? RaisedButton(
                    child: Text('Collect user data'),
                    onPressed: () {
                      context.router.root.push(UserDataCollectorRoute(onResult: (data) {
                        setState(() {
                          userData = data;
                        });
                      }));
                    })
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Your Data is complete'),
                      const SizedBox(height: 24),
                      Text('Name: ${userData.name}'),
                      const SizedBox(height: 24),
                      Text('Favorite book: ${userData.favoriteBook}'),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}
