import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  UserData? userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Profile page',
                style: Theme.of(context).textTheme.titleLarge,
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
                  context.findRootAncestorStateOfType<HomePageState>()?.toggleSettingsTap();
                },
                child: Text('Toggle Settings Tab'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.back(),
                child: Text('Navigate Back'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.navigateToPath('settings/tab1');
                },
                child: Text('Navigate to settings/tab1'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.router.replaceAll(
                    [
                      HomeRoute(
                        children: [
                          SettingsTab(tab: 'Replaced'),
                        ],
                      ),
                    ],
                    updateExistingRoutes: false,
                  );
                },
                child: Text('ReplaceAll'),
              ),
              const SizedBox(height: 32),
              userData == null
                  ? ElevatedButton(
                      onPressed: () {
                        // context.pushRoute(
                        //   // UserDataCollectorRoute(onResult: (data) {
                        //   //   setState(() {
                        //   //     userData = data;
                        //   //   });
                        //   // }),
                        // );
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
      ),
    );
  }
}
