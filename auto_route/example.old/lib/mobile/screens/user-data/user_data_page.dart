import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class UserDataPage extends StatelessWidget {
  const new({super.key, this.onResult});
  // The generated router copies this type into its args class.
  // ignore: inference_failure_on_function_return_type
  final Function(UserData data)? onResult;

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<SettingsState>().userData;
    return Scaffold(
      body: Padding(
        padding: const .symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .stretch,
          spacing: 24,
          children: [
            const Text('Success'),
            Text('Name: ${userData.name}'),
            Text('Favorite book: ${userData.favoriteBook}'),
            ElevatedButton(
              onPressed: () {
                unawaited(context.router.maybePopTop(userData));
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
