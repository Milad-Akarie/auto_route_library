part of 'deferred_first_page.dart';

/// A page in the same library as [DeferredFirstPage], without its own request
/// for deferred loading.
@RoutePage()
class DeferredSecondPage extends StatelessWidget {
  /// Creates the page, which shows a fixed text.
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Second page'));
}
