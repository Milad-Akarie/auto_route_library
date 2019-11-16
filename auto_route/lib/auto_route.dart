class AutoRoute {
  final String name;
  final bool fullscreenDialog;
  final bool maintainState;
  final Function transitionBuilder;
  final int durationInMilliseconds;

  const AutoRoute({this.name, this.fullscreenDialog, this.maintainState, this.transitionBuilder, this.durationInMilliseconds});
}
