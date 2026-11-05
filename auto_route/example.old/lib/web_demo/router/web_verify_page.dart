import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/app.dart';
import 'package:material_ui/material_ui.dart';

/// Verification page; pressing the button marks the user as verified.
@RoutePage()
class WebVerifyPage extends StatelessWidget {
  /// Takes [onResult].
  const new({super.key, this.onResult});

  /// Not called by this page.
  final ValueChanged<bool>? onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            App.of(context).authService.isVerified = true;
          },
          child: const Text('verify'),
        ),
      ),
    );
  }
}
