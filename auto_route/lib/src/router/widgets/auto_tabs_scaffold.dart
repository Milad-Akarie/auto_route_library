import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef AppBarBuilder = PreferredSizeWidget Function(
  BuildContext context,
  TabsRouter tabsRouter,
);

typedef BottomNavigationBuilder = Widget Function(
  BuildContext context,
  TabsRouter tabsRouter,
);

class AutoTabsScaffold extends StatelessWidget {
  final AnimatedIndexedStackBuilder? builder;
  final List<PageRouteInfo> routes;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool lazyLoad;
  final BottomNavigationBuilder? bottomNavigationBuilder;
  final NavigatorObserversBuilder navigatorObservers;
  final bool inheritNavigatorObservers;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Color? drawerScrimColor;
  final Color? backgroundColor;
  final Widget? bottomSheet;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final AppBarBuilder? appBarBuilder;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int homeIndex;
  const AutoTabsScaffold({
    Key? key,
    required this.routes,
    this.lazyLoad = true,
    this.homeIndex = -1,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.ease,
    this.builder,
    this.bottomNavigationBuilder,
    this.inheritNavigatorObservers = true,
    this.navigatorObservers =
        AutoRouterDelegate.defaultNavigatorObserversBuilder,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.drawerScrimColor,
    this.backgroundColor,
    this.bottomSheet,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.appBarBuilder,
    this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: routes,
      duration: animationDuration,
      lazyLoad: lazyLoad,
      homeIndex: homeIndex,
      navigatorObservers: navigatorObservers,
      inheritNavigatorObservers: inheritNavigatorObservers,
      curve: animationCurve,
      builder: (context, child, animation) {
        final tabsRouter = context.tabsRouter;
        return Scaffold(
          key: scaffoldKey,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          endDrawer: endDrawer,
          extendBody: extendBody,
          restorationId: restorationId,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          backgroundColor: backgroundColor,
          drawer: drawer,
          drawerDragStartBehavior: drawerDragStartBehavior,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
          drawerScrimColor: drawerScrimColor,
          onDrawerChanged: onDrawerChanged,
          endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
          onEndDrawerChanged: onEndDrawerChanged,
          floatingActionButton: floatingActionButton,
          floatingActionButtonAnimator: floatingActionButtonAnimator,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomSheet: bottomSheet,
          persistentFooterButtons: persistentFooterButtons,
          primary: primary,
          appBar: appBarBuilder == null
              ? null
              : appBarBuilder!(
                  context,
                  tabsRouter,
                ),
          body: builder == null
              ? FadeTransition(opacity: animation, child: child)
              : builder!(
                  context,
                  child,
                  animation,
                ),
          bottomNavigationBar: bottomNavigationBuilder == null
              ? null
              : bottomNavigationBuilder!(
                  context,
                  tabsRouter,
                ),
        );
      },
    );
  }
}
