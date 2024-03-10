//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.gr.dart';
import 'package:example/web_demo/services/auth_service.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:example/web_demo/widgets/logout_button.dart';
import 'package:example/web_demo/widgets/router_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MainWebPage extends StatefulWidget {
  const MainWebPage({Key? key}) : super(key: key);

  @override
  State<MainWebPage> createState() => _MainWebPageState();
}

class _MainWebPageState extends State<MainWebPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RouterAppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HomePage',
              style: TextStyle(fontSize: 30),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  final route = UserRoute(
                    id: 2,
                    query: const ['value1', 'value2'],
                  );
                  AutoRouter.of(context).push(route);
                  // context.pushRoute(route);
                },
                child: Text('Navigate to user/2'),
              ),
            ),
            LogoutButton(),
            if (kIsWeb)
              ElevatedButton(
                onPressed: () {
                  final currentState = ((context.router.pathState as int?) ?? 0);
                  context.router.pushPathState(currentState + 1);
                },
                child: AnimatedBuilder(
                  animation: context.router.navigationHistory,
                  builder: (context, _) {
                    return Text('Update State: ${context.router.pathState}');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
