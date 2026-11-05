import 'package:example/web_demo/app.dart';
import 'package:material_ui/material_ui.dart';

/// Page with buttons that sign in, verify, or do both.
class LoginPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to continue')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isAuthenticated = true;
              },
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.isVerified = true;
              },
              child: const Text('Verify'),
            ),
            ElevatedButton(
              onPressed: () {
                App.of(context).authService.loginAndVerify();
              },
              child: const Text('Login & Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
