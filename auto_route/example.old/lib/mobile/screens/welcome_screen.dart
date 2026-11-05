import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/app_router.gr.dart';
import 'package:material_ui/material_ui.dart';

/// A page with a button that opens the home page.
@RoutePage()
class WelcomeScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoLeadingButton.builder(
      builder: (context, leading) {
        return Scaffold(
          appBar: AppBar(
            leading: leading,
            title: const Text('Welcome'),
            centerTitle: false,
          ),
          body: Center(
            child: ElevatedButton(
              child: const Text('Dashboard'),
              onPressed: () {
                unawaited(context.pushRoute(const HomeRoute()));
              },
            ),
          ),
        );
      },
    );
  }
}
