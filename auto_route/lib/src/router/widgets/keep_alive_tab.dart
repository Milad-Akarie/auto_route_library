part of 'auto_tabs_router.dart';

/// A Wrapper widget to utilize [AutomaticKeepAliveClientMixin]
class KeepAliveTab extends StatefulWidget {
  /// Default contractor
  const new({required this.page, super.key, this.initiallyLoaded = true});

  /// Whether the tab should be initially loaded
  final bool initiallyLoaded;

  /// The tab page to keep-alive
  final AutoRoutePage<Object?> page;

  @override
  State<KeepAliveTab> createState() => KeepAliveTabState();
}

/// The state of [KeepAliveTab]
class KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  late bool _load = widget.initiallyLoaded;

  /// preloads the tab so other navigation actions can be done
  /// before the tab is initialized
  bool preload() {
    if (_load) return false;
    setState(() {
      _load = true;
    });
    return true;
  }

  /// unloads the tab if it's not needed
  void unloadIfRequired() {
    if (_load && !widget.page.maintainState) {
      setState(() {
        _load = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Semantics(
      role: .tabPanel,
      child: _load ? widget.page.buildPage(context) : const SizedBox.shrink(),
    );
  }

  @override
  bool get wantKeepAlive => widget.page.maintainState;
}
