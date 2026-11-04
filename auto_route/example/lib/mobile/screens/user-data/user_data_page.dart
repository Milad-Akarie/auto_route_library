import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/screens/user-data/data_collector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

//ignore_for_file: public_member_api_docs
class UserDataPage extends StatelessWidget {
  const UserDataPage({super.key, this.onResult});
  final Function(UserData data)? onResult;

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<SettingsState>().userData;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Success'),
            const SizedBox(height: 24),
            Text('Name: ${userData.name}'),
            const SizedBox(height: 24),
            Text('Favorite book: ${userData.favoriteBook}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.router.maybePopTop(userData);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
