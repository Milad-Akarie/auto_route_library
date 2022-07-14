import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:flutter/material.dart';

import '../../router/router.gr.dart';
import '../user-data/data_collector.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserData? userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profile page',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.router.push(MyBooksRoute());
              },
              child: Text('My Books'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context
                    .findRootAncestorStateOfType<HomePageState>()
                    ?.toggleSettingsTap();
              },
              child: Text('Toggle Settings Tab'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateBack();
              },
              child: Text('Navigate Back'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateNamedTo('settings/хиты');
              },
              child: Text('Navigate to settings/tab1'),
            ),
            const SizedBox(height: 32),
            userData == null
                ? ElevatedButton(
                    onPressed: () {
                      context.pushRoute(
                        UserDataCollectorRoute(onResult: (data) {
                          setState(() {
                            userData = data;
                          });
                        }),
                      );
                    },
                    child: Text('Collect user data'),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Your Data is complete'),
                      const SizedBox(height: 24),
                      Text('Name: ${userData!.name}'),
                      const SizedBox(height: 24),
                      Text('Favorite book: ${userData!.favoriteBook}'),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}
