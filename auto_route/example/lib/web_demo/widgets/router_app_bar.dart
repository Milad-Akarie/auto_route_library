//ignore_for_file: public_member_api_docs
import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/app_router.dart';
import 'package:flutter/material.dart';

class RouterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  const RouterAppBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final router = AutoRouter.of(context);
    return AppBar(
      leadingWidth: 500,
      leading: Row(
        children: [
          SizedBox(width: 12),
          AutoLeadingButton(),
          SizedBox(width: 4),
          TextButton(
            onPressed: () async {
              print("Can Pop: ${router.canPop()}");
              _printStack(context);
              final didPop = await router.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Did Pop: $didPop'),
                ),
              );
            },
            child: Text("Pop"),
          ),
          SizedBox(width: 4),
          TextButton(
            onPressed: () async {
              final _router = router.root;
              print("Can Pop Root Router: ${_router.canPop()}");
              _printStack(context);
              final didPop = await _router.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Did Pop Root Router: $didPop'),
                ),
              );
            },
            child: Text("Pop (root router)"),
          ),
          SizedBox(width: 4),
          TextButton(
            onPressed: () async {
              print("Can Pop: ${router.canPop()}");
              _printStack(context);
              // This pops until the root route, but does not remove the root route itself
              router.popUntilRoot();
            },
            child: Text("Pop Until Root"),
          ),
          SizedBox(width: 4),
          TextButton(
            onPressed: () async {
              print("Can Pop: ${router.canPop()}");
              _printStack(context);
              // This pops a route regardless of whether it is the root route or not
              router.popForced();
            },
            child: Text("Force Pop"),
          )
        ],
      ),
      title: title,
    );
  }

  void _printStack(BuildContext context) {
    final router = context.router as AppRouter;
    router.printRouterStack();
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
