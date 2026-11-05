import 'package:auto_route/auto_route.dart';
import 'package:example/declarative/declarative.router.gr.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(DeclarativeNavigationExampleApp());
}

/// Routes of the declarative navigation example.
///
/// One main route holds the three steps (name, age and result) as children.
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

/// Root widget of the declarative navigation example.
///
/// Asks for a name and an age, then shows both, with the visible step chosen by
/// the data entered so far.
class DeclarativeNavigationExampleApp extends StatelessWidget {
  /// Creates the app, which builds its own [DecRouter].
  new({super.key});
  final _router = DecRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router.config());
  }
}

/// Host page of the declarative example.
///
/// Keeps the profile entered so far and lets it decide which step shows.
@RoutePage()
class MainScreen extends StatefulWidget {
  /// Creates the page.
  const new({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ValueNotifier<Profile> _profileNotifier = ValueNotifier(
    const Profile(),
  );

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

/// First step of the declarative example: asks for a name.
@RoutePage()
class NameInputScreen extends StatefulWidget {
  /// Takes the callback that receives the name when the user submits it.
  const new({required this.onNameSubmitted, super.key});

  /// Called with the entered text when the user submits the name.
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

/// Second step of the declarative example: asks for an age.
// age submit page
@RoutePage()
class AgeInputScreen extends StatefulWidget {
  /// Takes the callback that receives the age when the user submits it.
  const new({required this.onAgeSubmitted, super.key});

  /// Called with the entered number when the user submits the age.
  ///
  /// The text is parsed as an integer, so a non-numeric entry throws a
  /// [FormatException].
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

/// Last step of the declarative example: shows the profile and a reset button.
@RoutePage()
class ResultScreen extends StatelessWidget {
  /// Both arguments are required.
  const new({required this.profile, required this.onReset, super.key});

  /// The name and age to show.
  final Profile profile;

  /// Called when the user presses the reset button.
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
              Text('Name: ${profile.name ?? 'null'}'),
              Text('Age: ${profile.age ?? 'null'}'),
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

/// The name and age collected so far by the declarative example.
///
/// A `null` field means that step is not done yet.
class Profile {
  /// Creates a profile; both fields start empty.
  const new({this.name, this.age});

  /// The entered name, or `null` before it is submitted.
  final String? name;

  /// The entered age, or `null` before it is submitted.
  final int? age;

  /// Returns a copy with [name] and [age] replaced when they are not `null`.
  Profile copyWith({String? name, int? age}) {
    return Profile(name: name ?? this.name, age: age ?? this.age);
  }
}
