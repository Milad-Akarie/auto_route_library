import 'package:auto_route/auto_route.dart';
import 'package:example/declarative/declarative.router.gr.dart';
import 'package:material_ui/material_ui.dart';

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
  new({super.key});
  final _router = DecRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router.config(),
    );
  }
}

@RoutePage()
class MainScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _profileNotifier = ValueNotifier<Profile>(const Profile());

  @override
  void dispose() {
    _profileNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Declarative Navigation Example')),
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
  const new({super.key, required this.onNameSubmitted});
  final ValueChanged<String> onNameSubmitted;

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const .all(16),
          child: Column(
            children: [
              const Text('Enter your name'),
              TextField(controller: _controller, textAlign: .center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onNameSubmitted(_controller.text);
                },
                child: const Text('Submit'),
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
  const new({super.key, required this.onAgeSubmitted});
  final ValueChanged<int> onAgeSubmitted;

  @override
  State<AgeInputScreen> createState() => _AgeInputScreenState();
}

class _AgeInputScreenState extends State<AgeInputScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const .all(16),
          child: Column(
            children: [
              const Text('Enter your age'),
              TextField(controller: _controller, textAlign: .center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onAgeSubmitted(int.parse(_controller.text));
                },
                child: const Text('Submit'),
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
  const new({super.key, required this.profile, required this.onReset});
  final Profile profile;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const .all(16),
          child: Column(
            children: [
              Text('Name: ${profile.name}'),
              Text('Age: ${profile.age}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onReset,
                child: const Text('Reset State'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Profile {
  const new({this.name, this.age});

  final String? name;
  final int? age;

  Profile copyWith({String? name, int? age}) {
    return Profile(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}
