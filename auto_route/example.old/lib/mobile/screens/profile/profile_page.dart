import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:example/mobile/screens/home_page.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:material_ui/material_ui.dart';

/// Page of the profile tab with buttons that test navigation.
@RoutePage()
class ProfilePage extends StatefulWidget {
  /// Creates the page.
  const new({super.key});

  @override
  ProfilePageState createState() => .new();
}

/// State of [ProfilePage]; holds the data the user collected.
class ProfilePageState extends State<ProfilePage> {
  /// The data from the user data flow, or `null` while it is not collected.
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
                  context
                      .findRootAncestorStateOfType<HomePageState>()
                      ?.toggleSettingsTap();
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
                        HomeRoute(children: [SettingsTab(tab: 'Replaced')]),
                      ],
                      updateExistingRoutes: false,
                    ),
                  );
                },
                child: const Text('ReplaceAll'),
              ),
              const SizedBox(height: 32),
              if (userData != null)
                Column(
                  mainAxisAlignment: .center,
                  spacing: 24,
                  children: [
                    const Text('Your Data is complete'),
                    Text('Name: ${userData!.name ?? 'null'}'),
                    Text('Favorite book: ${userData!.favoriteBook ?? 'null'}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
