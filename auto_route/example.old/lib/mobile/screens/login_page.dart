import 'package:auto_route/annotations.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Mock login page; pressing the button signs the user in through the
/// [AuthService] above it.
@RoutePage()
class LoginPage extends StatelessWidget {
  /// Takes [shouldShowBackButton].
  const new({super.key, this.shouldShowBackButton = true});

  /// Whether the app bar may show a back button; defaults to `true`.
  final bool shouldShowBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login page'),
        automaticallyImplyLeading: shouldShowBackButton,
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
