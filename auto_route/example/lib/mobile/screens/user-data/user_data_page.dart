import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_collector.dart';

//ignore_for_file: public_member_api_docs
class UserDataPage extends StatelessWidget {
  final Function(UserData data)? onResult;

  const UserDataPage({super.key, this.onResult});

  @override
  Widget build(BuildContext context) {
    var userData = context.watch<SettingsState>().userData;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Success'),
            const SizedBox(height: 24),
            Text('Name: ${userData.name}'),
            const SizedBox(height: 24),
            Text('Favorite book: ${userData.favoriteBook}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.router.maybePopTop(userData);
              },
              child: Text('Done'),
            )
          ],
        ),
      ),
    );
  }
}
