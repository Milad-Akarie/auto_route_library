import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/app.dart';
import 'package:material_ui/material_ui.dart';

/// Web login page; pressing the button signs the user in.
@RoutePage()
class WebLoginPage extends StatelessWidget {
  /// Takes [onResult].
  const new({super.key, this.onResult});

  /// Called with `true` after the user signs in.
  final ValueChanged<bool>? onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            App.of(context).authService.isAuthenticated = true;
            onResult?.call(true);
          },
          child: const Text('Login'),
        ),
      ),
    );
  }
}
