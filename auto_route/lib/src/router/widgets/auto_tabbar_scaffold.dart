import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AutoTabBarScaffold extends StatelessWidget {
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
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int homeIndex;
  final List<Tab> tabs;
  final List<Widget> tabsView;
  final Widget appBarTitle;
  final TabBarTheme? tabBarTheme;
  final Widget? appBarLeading;
  final List<Widget>? appBarActions;
  const AutoTabBarScaffold({
    Key? key,
    required this.routes,
    required this.tabs,
    required this.tabsView,
    required this.appBarTitle,
    this.tabBarTheme,
    this.appBarLeading,
    this.appBarActions,
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
    this.scaffoldKey,
  })  : assert(tabs.length == tabsView.length && tabs.length == routes.length),
        super(key: key);

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
      builder: (context, child, _) {
        final tabsRouter = context.tabsRouter;
        return DefaultTabController(
          length: tabsRouter.stack.length,
          child: Scaffold(
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
            appBar: AppBar(
              title: appBarTitle,
              leading: appBarLeading,
              actions: appBarActions,
              bottom: TabBar(
                tabs: tabs,
                onTap: tabsRouter.setActiveIndex,
                indicator: tabBarTheme?.indicator,
                indicatorSize: tabBarTheme?.indicatorSize,
                labelColor: tabBarTheme?.labelColor,
                labelPadding: tabBarTheme?.labelPadding,
                labelStyle: tabBarTheme?.labelStyle,
                unselectedLabelColor: tabBarTheme?.unselectedLabelColor,
                unselectedLabelStyle: tabBarTheme?.unselectedLabelStyle,
              ),
            ),
            body: TabBarView(children: tabsView),
          ),
        );
      },
    );
  }
}
