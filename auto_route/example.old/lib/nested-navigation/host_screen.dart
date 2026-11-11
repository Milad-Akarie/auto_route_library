import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Host page whose body is a nested router, with a back button when that router
/// can pop.
@RoutePage()
class HostScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Screen'),

        /// This will automatically display a back button if the nested router
        /// can pop
        leading: const AutoLeadingButton(),
      ),
      body: const AutoRouter(),
    );
  }
}
