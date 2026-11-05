import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:material_ui/material_ui.dart';

@RoutePage()
class WebVerifyPage extends StatelessWidget {
  const WebVerifyPage({super.key, this.onResult});
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
