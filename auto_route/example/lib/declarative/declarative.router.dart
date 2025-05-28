import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'declarative.router.gr.dart';

void main() {
  runApp(DeclarativeNavigationExampleApp());
}

@AutoRouterConfig(generateForDir: ['lib/declarative'])
class DecRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: MainRoute.page,
          initial: true,
          children: [
            AutoRoute(page: NameInputRoute.page),
            AutoRoute(page: AgeInputRoute.page),
            AutoRoute(page: ResultRoute.page),
          ],
        ),
      ];
}

class DeclarativeNavigationExampleApp extends StatelessWidget {
  final _router = DecRouter();

  DeclarativeNavigationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router.config(),
    );
  }
}

@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _profileNotifier = ValueNotifier<Profile>(const Profile());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Declarative Navigation Example')),
      body: ValueListenableBuilder(
        valueListenable: _profileNotifier,
        builder: (context, profile, _) {
          return AutoRouter.declarative(
            routes: (_) {
              return [
                if (profile.name == null)
                  NameInputRoute(
                    onNameSubmitted: (name) {
                      _profileNotifier.value = profile.copyWith(name: name);
                    },
                  ),
                if (profile.name != null && profile.age == null)
                  AgeInputRoute(
                    onAgeSubmitted: (age) {
                      _profileNotifier.value = profile.copyWith(age: age);
                    },
                  ),
                if (profile.name != null && profile.age != null)
                  ResultRoute(
                    profile: profile,
                    onReset: () {
                      _profileNotifier.value = const Profile();
                    },
                  ),
              ];
            },
          );
        },
      ),
    );
  }
}

@RoutePage()
class NameInputScreen extends StatefulWidget {
  final ValueChanged<String> onNameSubmitted;

  const NameInputScreen({super.key, required this.onNameSubmitted});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _controller = TextEditingController();

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Enter your name'),
              TextField(controller: _controller, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onNameSubmitted(_controller.text);
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// age submit page
@RoutePage()
class AgeInputScreen extends StatefulWidget {
  final ValueChanged<int> onAgeSubmitted;

  const AgeInputScreen({super.key, required this.onAgeSubmitted});

  @override
  State<AgeInputScreen> createState() => _AgeInputScreenState();
}

class _AgeInputScreenState extends State<AgeInputScreen> {
  final _controller = TextEditingController();

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Enter your age'),
              TextField(controller: _controller, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onAgeSubmitted(int.parse(_controller.text));
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@RoutePage()
class ResultScreen extends StatelessWidget {
  final Profile profile;
  final VoidCallback onReset;

  const ResultScreen({super.key, required this.profile, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Name: ${profile.name}'),
              Text('Age: ${profile.age}'),
              SizedBox(height: 16),
              ElevatedButton(onPressed: onReset, child: Text('Reset State')),
            ],
          ),
        ),
      ),
    );
  }
}

class Profile {
  const Profile({this.name, this.age});

  final String? name;
  final int? age;

  Profile copyWith({String? name, int? age}) {
    return Profile(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
