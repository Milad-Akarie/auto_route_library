import 'package:auto_route/annotations.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.showBackButton = true});
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login page'),
        automaticallyImplyLeading: showBackButton,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.read<AuthService>().login();
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
