import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:material_ui/material_ui.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => .new();
}

class ProfilePageState extends State<ProfilePage> {
  UserData? userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              Text(
                'Profile page',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  unawaited(context.router.push(MyBooksRoute()));
                },
                child: const Text('My Books'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  context.findRootAncestorStateOfType<HomePageState>()?.toggleSettingsTap();
                },
                child: const Text('Toggle Settings Tab'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.back(),
                child: const Text('Navigate Back'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  unawaited(context.navigateToPath('settings/tab1'));
                },
                child: const Text('Navigate to settings/tab1'),
              ),
              ElevatedButton(
                onPressed: () {
                  unawaited(
                    context.router.replaceAll(
                      [
                        HomeRoute(
                          children: [
                            SettingsTab(tab: 'Replaced'),
                          ],
                        ),
                      ],
                      updateExistingRoutes: false,
                    ),
                  );
                },
                child: const Text('ReplaceAll'),
              ),
              const SizedBox(height: 32),
              if (userData == null)
                ElevatedButton(
                  onPressed: () {
                    // context.pushRoute(
                    //   // UserDataCollectorRoute(onResult: (data) {
                    //   //   setState(() {
                    //   //     userData = data;
                    //   //   });
                    //   // }),
                    // );
                  },
                  child: const Text('Collect user data'),
                )
              else
                Column(
                  mainAxisAlignment: .center,
                  spacing: 24,
                  children: [
                    const Text('Your Data is complete'),
                    Text('Name: ${userData!.name}'),
                    Text('Favorite book: ${userData!.favoriteBook}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
