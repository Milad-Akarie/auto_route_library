import 'package:flutter/material.dart';

void main() => runApp(const NavigatorPopHandlerApp());

class NavigatorPopHandlerApp extends StatelessWidget {
  const NavigatorPopHandlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Navigator(
        pages: [
          MaterialPage<void>(
            key: const ValueKey<String>('pageOne'),
            child: const _HomePage(),
          ),
          MaterialPage<void>(
            key: const ValueKey<String>('pageTwo'),
            child: const _PageTwo(),
          ),
        ],
        onPopPage: (Route<void> route, void result) {
          if (!route.didPop(result)) {
            print('onPopPage: didPop: false');
            return false;
          }
          print('onPopPage: didPop: true');
          route.onPopInvoked(true);
          return true;
        },
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Page One'),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/two');
              },
              child: const Text('Next page'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTwo extends StatefulWidget {
  const _PageTwo();

  @override
  State<_PageTwo> createState() => _PageTwoState();
}

class _PageTwoState extends State<_PageTwo> {
  void _showBackDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'Are you sure you want to leave this page?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Page Two'),
            PopScope(
              canPop: false,
              onPopInvoked: (bool didPop) {
                print('didPop: $didPop');
                if (didPop) {
                  return;
                }
                _showBackDialog();
              },
              child: TextButton(
                onPressed: () {
                  Navigator.maybePop(context);
                  // _showBackDialog();
                },
                child: const Text('Go back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
