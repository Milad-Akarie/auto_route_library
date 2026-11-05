import 'package:auto_route/auto_route.dart';
import 'package:example/declarative/dec_router.gr.dart';
import 'package:example/declarative/profile.dart';
import 'package:material_ui/material_ui.dart';

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
