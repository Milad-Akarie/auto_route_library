## 12.1.0
- **FEAT**: path and query params can be the app's own types: give `@PathParam` or `@QueryParam` a
  `ParamConverter<T>`, a top-level const, and the route reads the param with the new `Parameters.getTyped` or
  `optTyped` and writes it back with `toParam` (#1794).
- **FEAT**: a page class with type parameters gets a generic route: `PickerPage<T>` gives `PickerRoute<T>`, and
  `push<int>(PickerRoute<int>(...))` builds `PickerPage<int>`; a page opened from a link gets each type
  parameter's bound (#2050, #1879, #1739).
- **FEAT**: in debug builds, two routes with the same full path make the router throw a `FlutterError` naming
  both when it first reads its routes; paths that differ only in param names count as the same
  (flutter/flutter#190741).
- **FEAT**: `AutoTabsRouter` and `AutoTabsScaffold` take `backThroughHistory`: back shows the tabs visited before,
  the latest first, then leaves the tabs (#1789, #830).
- **FEAT**: `AutoTabsRouter.tabBar` and `AutoTabsRouter.pageView` take `lazyLoad`; `false` builds every tab's page
  up front (#2013).
- **FEAT**: every page's semantics carry its route name as their identifier, so UI testing tools such as Appium and
  Maestro, and `find.bySemanticsIdentifier` in widget tests, find a page by its route name, whatever its route
  type (#2115).
- **FEAT**: `CustomRoute(enableCupertinoBackGesture: true)`, also on `RouteType.custom`, keeps the iOS back swipe on a
  page with a custom transition, on iOS and macOS (flutter/flutter#183252).
- **FEAT**: `router.waitForTransitions()` completes once every page has stopped moving after a push, a replace or a
  pop, for example to open a bottom sheet once a page has come in (flutter/flutter#162789).

## 12.0.0
- **BREAKING CHANGE**: `RouteMatch.pathParams` and `RouteData.pathParams`, deprecated since 11.2.0, are removed;
  use `params`.
- **BREAKING CHANGE**: the `durationInMilliseconds` and `reverseDurationInMilliseconds` parameters of `CustomRoute`
  and `RouteType.custom`, deprecated since 11.2.0, are removed; pass `duration` and `reverseDuration`.
- **BREAKING CHANGE**: the `animatePageTransition` parameter of `AutoTabsRouter.tabBar`, deprecated since 11.2.0, is
  removed; pass `duration: Duration.zero` to switch tabs without animating.
- **FIX**: an app can catch a bad path param's error by its type: `MissingRequiredParameterError` is exported
  from `package:auto_route/auto_route.dart` (flutter/flutter#155598).
- **FIX**: a page view tabs router with a zero duration switches tabs without animating (#1150).
- `NavigationHistory`, the type of `router.navigationHistory`, is exported from `package:auto_route/auto_route.dart`,
  so an app can name it in a variable, a parameter or a test.
- **DEPRECATION**: passing a bool to `NavigationResolver.next` is deprecated; call `next()` to
  continue and the new `reject()` to stop, so `resolver.next(false)` becomes `resolver.reject()`.
- **DEPRECATION**: passing a bool to `NavigationResolver.nextOrBack` is deprecated;
  `nextOrBack(false)` becomes `reject(goBack: true)`.
- **DEPRECATION**: `NavigationResolver.resolveNext` is deprecated. `resolveNext(true, reevaluateNext: false)`
  becomes `overrideNext(reevaluateNext: false)`, and `resolveNext(false, reevaluateNext: false)`
  becomes `reject(reevaluateNext: false)`.
- **BREAKING CHANGE** (behavior): the futures of `pushAll` and `popAndPushAll` complete once every
  guard has decided, instead of at once, as `replaceAll`'s already did. Code after `await router.pushAll(...)` now sees
  the new stack, or the old one when a guard rejected it; don't await it inside a guard of the same
  routes.
- **BREAKING CHANGE** (an analyzer warning only): `Parameters`, `PageInfo`, `RouteType`,
  `RouteCollection`, `HierarchySegment` and `AutoRouteInformation` are `@immutable`, since they
  define `==`. A subclass with a field that isn't `final` now gets `must_be_immutable`; make it final.
- **DEPRECATION**: `copyWith` takes each field's own name. On `PageRouteInfo`, write `rawPathParams`,
  `rawQueryParams` and `initialChildren` instead of `params`, `queryParams` and `children`, and drop
  `path` and `match`, which did nothing; it can now also set `stringMatch`, `redirectedFrom` and
  `argsEquality`. On `RouteMatch`, write `params` instead of `pathParams`; it can now also set `id`.
- **BREAKING CHANGE**: `CupertinoRoute`, `AdaptiveRoute` and `CustomRoute` no longer take a type
  argument, which they never used. Write `CustomRoute(...)` instead of `CustomRoute<void>(...)`.
- **BREAKING CHANGE**: `OnNavigationChanged` is `void Function(TabsRouter)`, and `popAndPushAll`'s
  `onFailure` is an `OnNavigationFailure?` instead of `dynamic`. Callbacks written as closures
  compile as before; pass `onFailure` a `void Function(NavigationFailure)`, as `pushAll` takes.
- **DEPRECATION**: `RouteData.setAnimation(a)` is deprecated; write `routeData.animation = a`.
  `RouteData.animation` can now be read too. `RouteData.args` stays `Object?`: a route's args can be
  any class, so read them typed with `argsAs<T>()`.
- **BREAKING CHANGE**: `NavigationResolver.redirectUntil` returns `Future<void>` instead of `void`,
  completing once the redirect route closes. Calls compile as before; a class that overrides it
  must return `Future<void>`, and a lint that asks for it is answered with `unawaited(...)`.
- **CHORE**: require Dart 3.13, the version Flutter 3.47 ships. The package already required
  Flutter 3.47, so no app that could use it before is left out.
- **BEHAVIOR CHANGE**: `pushAndPopUntil` now removes the routes below the new page instead of
  popping them, like `Navigator.pushAndRemoveUntil`, so they no longer flash while the new page
  slides in. Navigator observers get `didRemove` for those routes, not `didPop`; the PopScope of
  the removed routes is not asked; their push futures complete with null. They are removed only
  once the new page's guards let it through, so a rejected push leaves the stack as it was,
  fixes #1797
- **BEHAVIOR CHANGE**: urls split only at '/' on every platform, so on Windows a backslash in a
  route path no longer separates segments, and `RouteData.match` joins segments with '/', not '\'.
- **FIX**: on web, a url whose first segment ends in ':' (like `/c:/files`) keeps its leading '/'.
- **FIX**: a `CustomRoute` or `RouteType.custom` with `barrierDismissible: true` pops on a tap on its
  barrier; the flag had no effect. `CustomRoute`'s `barrierDismissible` now defaults to false, as
  `RouteType.custom` and `PageRouteBuilder` do, so a route that doesn't set it behaves as before.
- **BREAKING CHANGE**: `auto_route` requires Flutter 3.47 (its pubspec now says so; it imported
  `material_ui` and `cupertino_ui`, which already needed it, and on older Flutter pub's error named
  those packages instead of this one). Upgrade Flutter, or stay on the release you use.
- **BEHAVIOR CHANGE**: an enum query parameter is read and written by its name. Before, a page
  with `@QueryParam('type') CartType? type` opened from `/cart?type=rm` threw a type error, and a
  push wrote `type=CartType.rm`. Now the url holds `type=rm`; an unknown name reads as null, or as
  the default. Regenerate your router; a link you saved in the old `CartType.rm` form no longer
  reads, fixes #2148
- **BEHAVIOR CHANGE**: a path param holding '/', '?' or '#' is encoded in the url and read back
  whole: `FilesRoute(path: 'reports/2024')` is `/files/reports%2F2024`, and a link with `%2F` no
  longer splits into two segments. `currentUrl` also keeps `=`, `&`, `+` and the other delimiters
  of a param encoded, so opening `currentUrl` again reads the same query, fixes #2070, #1925
- **BEHAVIOR CHANGE**: every tab change asks the tab route's guards, as a stack asks before a push.
  A tab whose guard rejects no longer shows when you call `setActiveIndex`, navigate to it, open
  its url or swipe to it; a guard that decides later (`redirectUntil`) keeps the current tab until
  then. Guards in `RootStackRouter.guards` are still not asked for tabs. A guard on a tab route
  that rejected without anyone noticing now takes effect, fixes #2218
- **BEHAVIOR CHANGE**: a guard that redirects a route to itself (`redirectUntil` to a route its
  own guard sends back) now reports a `FlutterError` naming the route and rejects the navigation,
  instead of looping to a white screen, fixes #2213, #1818
- **BEHAVIOR CHANGE**: `replace()` removes the page only once the new route's guards let it
  through, so a rejected `replace()` keeps the page and the url, fixes #2046. `replaceAll()` keeps
  the old pages until then and, when a guard rejects one of the new routes, puts them back: a
  rejected route rejects the whole batch, in nested routers too, fixes #2299
- **BEHAVIOR CHANGE**: a page whose required args weren't saved is left out of a restored stack
  instead of failing, fixes #2098
- **BEHAVIOR CHANGE**: `AutoRouteObserver` tells the popped page `didPop` before it tells the page
  under it `didPopNext`, on a pop and on a remove that uncovers a page; before, the page under
  heard first. A push already ran in this order, flutter/flutter#26902
- **BEHAVIOR CHANGE**: `navigate()` from a tab to a route that is a child of the tabs host's route
  but not one of its `AutoTabsRouter`'s routes now calls `onFailure` with a
  `RouteNotFoundFailure`, or throws; before, it did nothing, fixes #1371
- **BEHAVIOR CHANGE**: `popUntil` and `popUntilRoot` remove the pages between the top page and the
  one the predicate meets, then pop the top page with its animation, so the pages in between no
  longer show. Navigator observers hear `didRemove` for those pages, not `didPop`; their push
  futures complete with null as before, flutter/flutter#59990
- **BEHAVIOR CHANGE**: two `RedirectRoute`s that point at each other report a `FlutterError`
  naming the loop instead of overflowing the stack, flutter/flutter#104441
- **BEHAVIOR CHANGE**: a global guard's `redirect()` or `redirectPath()` that redirects again to
  where it came from, and two guards whose `redirectUntil()` send the user to each other's route,
  now report a `FlutterError` naming the loop and reject the route, instead of overflowing the
  stack or opening pages without end, flutter/flutter#118061
- **BEHAVIOR CHANGE**: `replace()` with a route of the same name and no children opens the route's
  initial child, as `navigate()` with the same route does; before, the nested router kept the child
  it showed. A route with no initial child still keeps it.
- **FEAT**: routers save their pages for state restoration (off the web): every page's name, path,
  query params and fragment, and each nested router's pages. Route args are your own objects and
  are not saved, so a page that needs required args is left out when restored.
- **FIX**: state restoration brings back every page of every stack and every tab, not only the
  one in the url, fixes #2040, #2041, #2099
- **FIX**: `Parameters.optBool` and `getBool` no longer crash on a bool pushed in code
  (`NamedRoute('Flag', queryParams: {'f': true})`) or restored by state restoration, fixes #2222
- **FIX**: `optString` and `getString` no longer throw a `TypeError` when the url repeats a query
  key (`/products?tag=red&tag=blue` reads the last value, `blue`) or when a number was pushed
  (`{'page': 2}` reads as '2').
- **FIX**: `AutoRouter.declarative(key: ...)` uses the key it is given.
- **FIX**: since 11.2.0 pages ignored the app's `Theme.pageTransitionsTheme` when the app's
  `MaterialApp` came from `package:flutter/material.dart`; they use it again, fixes #2340
- **FIX**: a deferred page popped before its library loads no longer throws "setState() called
  after dispose()".
- **FIX**: leaving a page no longer leaks, one more object on each visit, in a nested router, an
  `AutoTabsRouter` (the tab fade animation, and the `PageController` of `.pageView` and the tab-bar
  view) or an `AutoRouter.declarative` (its `HeroController`). Disposing a `RootStackRouter` now
  disposes its delegate, url provider and navigation history too, and disposing them twice is safe.
- **FIX**: a navigation stops when its nested router is disposed while a guard runs, fixes #2248
- **FIX**: a nested router keeps its open pages when its page builds it in another place, such as a
  list-detail page when a foldable phone folds.
- **FIX**: a pushed route with children keeps its fragment in the url (`/books#top`, not `/books`);
  `PageRouteInfo.copyWith` no longer drops `fragment`, `stringMatch`, `redirectedFrom` or
  `argsEquality`.
- **FIX**: on web, a deep link to an app that builds its router after the first frame keeps one
  history entry.
- **FIX**: on web, a deep link with an encoded character adds no second history entry.
- **FIX**: on web, the browser's back button leaves a page whose query params changed in place (`/page` to
  `/page?p=true`): it shows `/page` again, instead of staying on `/page?p=true`, flutter/flutter#108714.
- **FIX**: on web, the browser forward button returns to a page pushed over one with the same url.
- **FIX**: on web, going back returns to a previous page with the same url, such as a `Book` page
  pushed twice with different args.
- **FIX**: on web, a url with a letter outside ASCII follows the pages; a '#' in a path param
  survives a refresh, fixes #1812
- **FIX**: `back()` and the browser's back button return to the first of a route pushed twice with
  equal arguments, instead of the page before both; `back()` twice in a row works, and on native
  platforms `back()` over two pages with the same url returns to the first.
- **FIX**: the args and the children a guard sets with `overrideNext` show on the page and open
  in its nested router, also on a guard re-check.
- **FIX**: a guard re-check no longer runs an async simple guard twice.
- **FIX**: a page popped while guards are reevaluated stays closed, fixes #1643, #1785
- **FIX**: `replaceAll()` right after the reevaluate listenable changes replaces the stack, fixes #2172
- **FIX**: `replaceAll` and `pushAll` open routes of a closed nested router together, fixes #2214
- **FIX**: `popAndPushAll` from a router's only page replaces that page, fixes #1948
- **FIX**: `removeWhere` on a page below a page of the same route no longer removes the top page,
  fixes #1943
- **FIX**: a guard's redirect page leaves no history entry behind, fixes #2331
- **FIX**: awaiting `pushAll` waits for its guards to decide (see the breaking change).
- **FIX**: `pushAndPopUntil` no longer shows the pages it removes, fixes #1797
- **FIX**: `pushAndPopUntil(scopedPopUntil: false)` removes the pages a nested router's predicate
  rejects instead of animating them out, and leaves the page of a nested router that goes with its
  shell under the new page, not a blank shell (#1797).
- **FIX**: `navigate()` opens the right tab when two tabs share a route, keeps the path params it
  inherits (#1816), and fills a path param into the parent path that holds it (#2066).
- **FIX**: `navigatePath()` with an absolute path from a nested page opens its page, fixes #2317
- **FIX**: `currentHierarchy()` lists the children of a router nested twice, fixes #2321
- **FIX**: a tabs page opened at its own url (`/tabs`) now records its first tab in the url, so
  going back to that entry from another tab shows the first tab.
- **FIX**: observers hear `didInitTabRoute`, not `didChangeTabRoute`, when a swipe opens a tab
  for the first time.
- **FIX**: the url follows the active tab when two tabs share a parent route, fixes #1874
- **FIX**: removing a tab before the active tab keeps the active tab shown (#1786, also in the page-view kind); removing the
  active tab no longer throws a `RangeError` (#2308); a tab-bar `AutoTabsRouter` removed
  mid-animation no longer crashes (#1765).
- **FIX**: screen readers work again in `AutoTabsRouter.pageView` and `.tabBar`: tabs beside the
  open tab no longer reach them, fixes #2170
- **FIX**: back on a tab away from the home tab shows the home tab instead of closing the app on
  Android 13 and later, fixes #2059; back acts on the tab on screen, not a hidden one, fixes #2225
- **FIX**: a `PopScope` on a declarative nested router's page blocks the back gesture, fixes #2023
- **FIX**: a Hero flies from a page to the first page of a nested router, fixes #2024, #1873
- **FIX**: a `customRouteBuilder` page shows new query params after `replace()`, fixes #1857
- **FIX**: observers hear the right events: `navigateTo()` back to a page right after closing a
  dialog tells it `didPopNext` (#1774); a page in a nested router hears `didPop` when its host
  route is popped (#1863) and hears its host route covered and uncovered (#1954).
- **FIX**: "Can not resolve initial route" names the link no route matched and the catch-all
  `RedirectRoute(path: '*', redirectTo: '/')` that answers it, fixes #2119
- **FIX**: the example app builds for Android again on Flutter 3.47.
- **FIX**: routes with equal list or set url params are equal and hash equally, so
  `TagsRoute(tags: {'a'}) == TagsRoute(tags: {'a'})`.
- **FIX**: a path param whose name starts another param's name expands whole: with params `id`
  and `idx`, `/a/:idx` no longer becomes `/a/1x`, also through a `RedirectRoute`.
- **FIX**: `pop()` right after `push()` closes the pushed page instead of the page under it; on
  the first page it no longer leaves only the pushed one, flutter/flutter#145573. System back,
  `pop` or `maybePop` in the same frame as `replaceAll([Home])` keeps the new page instead of
  leaving none.
- **FIX**: `navigate`, `navigatePath` and `replaceAll` close the routes pushed with
  `Navigator.push` over the page they land on, flutter/flutter#171962
- **FIX**: a pushed page's future completes with its route's `currentResult` when the back gesture
  or system back closes it, as `Navigator.push` does, instead of null, flutter/flutter#171130
- **FIX**: two buttons pressed at once open only the first page, and a finger lifted from a
  button after another page opened over it opens nothing, flutter/flutter#160504
- **FIX**: opening a deeper page by its path (`/a`, then `/a/b`) no longer builds the pages under
  it again, flutter/flutter#147639
- **FIX**: routes added to the router before a hot reload open by path, push or link, also as
  children of a nested router on screen, flutter/flutter#105553
- **FIX**: on web, the browser's back button walks back through one route pushed several times
  with different params, flutter/flutter#186052
- **FIX**: on web, the browser's back button leaves the login page a guard redirected to after a
  logout, instead of showing it again on every press, flutter/flutter#135359
- **FIX**: on web, an app the user comes back to with the browser's back button, or reloads, reads
  the state it saved with `pushPathState`, instead of null, flutter/flutter#108697
- **FIX**: with state restoration, a link that starts an app the platform ended in the background
  opens its page instead of being ignored, flutter/flutter#161858
- **FIX**: a page built under a deep link (Home under `/b`) hears `didPushNext` when it subscribes
  to `AutoRouteObserver`, flutter/flutter#70272
- **FIX**: a widget with `AutoRouteAwareStateMixin` shown in a dialog no longer throws,
  flutter/flutter#62023
- **FIX**: widgets laid out before a nested router stay in the semantics tree, so screen readers
  read them, flutter/flutter#150978
- **FIX**: the predictive back gesture belongs to the page on screen when a nested router sits
  under a root page, flutter/flutter#152323
- **FIX**: a page closed in the same frame as its dialog animates out with it instead of
  vanishing at once, flutter/flutter#111137
- **FIX**: an empty list query param leaves no '?' at the end of the url (`/items`, not `/items?`),
  flutter/flutter#127373
- **FIX**: a path param named with a '$' (`:user$id`) is filled into the url, fixes #1163
- **FIX**: `replace()` and `pushAndPopUntil()` with a route of the same name and new nested
  children show only those children; before, both kept the nested pages they showed, fixes #1363
- **FIX**: `popUntilRouteWithName` and `popUntilRouteWithPath` with a page that isn't in the stack
  stop at the first page instead of leaving a blank screen, fixes #1502
- **FIX**: `pushPath` of an unknown relative path in a nested router calls `onFailure`, or throws,
  instead of pushing the router's first page again, fixes #1648
- **FIX**: a link that comes while the first page waits on its guard keeps its pages, instead of
  the first page coming back on top once its guard resolves, fixes #1668
- **CHORE**: `AutoRoutePage` no longer removes a popped page from its router's stack itself. It did
  so to stop a flicker on Flutter 3.38 to 3.41 (flutter/flutter#178570), which Flutter 3.44 fixed.
- **PERF**: a url is matched against the routes several times faster, and the matcher splits urls
  at '/' itself; a tab switch builds the readable url once instead of on every read.
## 11.2.0
- **CHORE:** Migrate to material_ui and cupertino_ui packages
## 11.1.0
- **CHORE:** deprecate animatePageTransition #2301
- **Enhance:** add .named constructor to PageRouteInfo and AutoRoute to enable usage for shorthand
  named routes without code generation.

## 11.0.0 [Breaking Changes]

- **BREAKING CHANGE**: The `redirectUntil` method now returns `void` instead of `Future<T?>` and
  handles the completion of the pop completer internally
- **BREAKING CHANGE**: The `redirect` method in `AutoRouteGuard` has been renamed to `redirectUntil`
  to better reflect its behavior and avoid confusion
- **BREAKING CHANGE**: Removed deprecated APIs: `navigateNamed`, `popForced`, `replaceNamed`,
  `pushNamed`, and `navigateNamedTo`. Use `navigatePath`, `pop`, `replacePath`, `pushPath` instead

## 10.3.0

- **FEAT**: Correct back-navigation behavior with proper state tracking
- **FEAT**: Add async support and debug labels to `AutoRouteGuard`
- **FEAT**: Add `checkGuard` method to `NavigationResolver` for sequential guard execution
- **FEAT**: Implement comprehensive navigation history tracking with proper state management
- **FEAT**: Prevent duplicate consecutive entries in navigation history

## 10.2.3

- **REFACTOR**: Preserve match ID on route updates to prevent breaking child controllers during
  route updates or when replacing a route, fixes #2294
- **FIX**: AutoTabsRouter.tabBar: Switching non-adjacent tabs shows the initial tab briefly when
  tapping a tab then swiping, instead of the tab you're swiping toward, fixes #2283
- **REFACTOR**: Simplify PagelessRoutesObserver and address pop flicker by using the more efficient
  `didChangeTop` callback

## 10.2.2

- **FIX**: known predictive back gesture issues.
- **FIX**: add meta import to routing_controller.dart because some flutter versions require it.

## 10.2.1

- **FIX**: correctly handle parameter names by removing leading underscores
- **Enhance**: appBarBuilder in AutoTabsScaffold can return null now
- **FIX**: Fix WASM type mismatch.

## 10.2.0

- **FIX**: respect page.opaque for transparent route.
- **FIX**: handle dart:xxx.xxx.dart imports in type resolution (af60d79) when using lean_builder
- **REFACTOR**: introduce _genericRef function for improved type reference handling (d5ecf13)
- **FIX**: respect page.opaque for transparent route (52b71b7)
- **FIX**: Use immutable array for pending child routes, fixes #2210 (beb3ce0)
- **CHORE**:: extend support to analyzer 8 (b2cb61d)

## 10.1.2

- **FIX**: routing_controller.dart missing meta import

## 10.1.1

- **CHORE**: tidy up dependencies and sync with updated analyzer version.
- **FIX**: Add indexed stack semantics
- **FIX**: Allow PopCompleter to complete during route reevaluation when pop-completers are disabled

## 10.1.0+1

- **FEAT**: Add experimental support for lean_builder

## 10.1.0

- **FEAT**: Expose routeTraversalEdgeBehavior property from the underlying Navigator to allow
  customization of navigation stack edge behavior.
- **FIX**: Improve focus and semantics handling in AutoTabsRouter IndexedStack to exclude inactive
  tabs from focus traversal and semantics tree while preserving widget state.
- **FIX**: Fix tab routes observing issue where initiating tabs can be reported twice.
- **FIX**: Fix a couple core reevaluation issues.
- **FIX**: Generated code is not properly formatted #2174
- **FIX**: Fixed PageRouteInfo equality check regression introduced in v10.0.1 when using code
  generation with argsEquality: false, which now defaults to true. The equality operator no longer
  compares args by default unless argsEquality: true is explicitly set in AutoRouterConfig. This
  restores compatibility with previous versions and prevents navigation test failures due to custom
  argument classes lacking a proper == override.

## 10.0.1

- **REFACTOR**(custom_route): update route duration type from int to Duration.
- **FEAT**: add onGeneratePath callback to RootStackRouter to allow custom path generation.

## 10.0.0 [Minor Breaking Changes]

- **BREAKING CHANGE**: DeepLink and DeepLink.path will now use 'navigate' instead of push unless
  specified
- **BREAKING CHANGE**: ActiveGuardObserver.value will now return a GuardEntry instead of an
  AutoRouteGuard, use 'activeGuards' to get the list of active guards
- **FEAT**: add support for using auto_route with out code generation using NamedRouteDef and
  NamedRoute
  otherwise.
- **FEAT**: add support for android's predictive back gesture
- **FEAT**: optional args equality by setting AutoRouterConfig(argsEquality: true)
- **FEAT**: insert route method to StackRouter
- **FIX**: guard reevaluation was re-implemented to fix previous issues
- **FEAT**: expose Navigator.clipBehavior in both AutoRouterDelegate and AutoRouter
- **FIX**: using AutoTabsRouter.tabBar with maintainState: false and TabBar together, fails to load
  routes in some cases #2113
- **FEAT**: safe build context can now be accessed in AutoRouteGuard.onNavigation ->
  NavigationResolver.context
- **FEAT**: add a new way to override guarded routes using
  NavigationResolver.overrideNext
- **FIX**: AutoLeadingButton is not showing anything on a screen that combines
  AutoTabsScaffold and NestedRoute #2141
- **FIX**: redirect route doesn't pass query params the to redirectTo path
- **FIX**: generated PageRouteInfo breaks if widget tagged with @RoutePage parameter named
  children. #2149
- **FEAT**: add an AutoLeadingButton.builder to enable passing of nullable leading widget
- **FIX**: Fix a couple internal issues and migrate to using didRemovePage api
- **FEAT**: Parameters.getList now supports a default value
- **FIX**: Add required keyword to named required parameters in function parameters' arguments
- **FIX**: fix inheritPathParam didn't use the .inherit constructor
- **REFACTOR** rename a couple of apis (popForced -> pop, pushNamed -> pushPath, replaceNamed ->
  replacePath, navigateNamed -> navigatePath, pathParams -> params)

## 9.3.0+1

- **CHORE**: Fix some static analysis warnings

## 9.3.0

- **CHORE**: Resolve some deprecated APIs.

## 9.2.2

- **FIX**: Redirect route names are getting overridden in route collection.

## 9.2.1+1

No changes, changelog fix only.

## 9.2.1

- **CHORE**: Update web package to 1.0.0

## 9.2.0

- **FIX**: revert web package back to version ^0.5.1 because it's pinned in a lot of other packages.

## 9.1.0

- **FEAT**: Add query params options to redirectTo in RedirectRoute #1721.

## 9.0.1

- **FIX**: make EmptyShellRoute() a const.
- **Chore**: Add Declarative navigation example link
- **Chore**: Add Nested Navigation example link

## 9.0.0 [Breaking Changes]

- **BREAKING CHANGE**: No Router class will be generated anymore. Instead, you
  extend `RootStackRouter` from the `auto_route` package.
- **BREAKING CHANGE**: Providing return types inside `@RoutePage<Type>()` is no longer needed. you
  just provide the type as you push the page.
- **BREAKING CHANGE**: Providing a global route is now done by overriding the `guards` property
  inside the router. implementing AutoRouteGuard is no longer supported.
- **BREAKING CHANGE**: `AutoRouterConfig.module` is removed as it's no longer
  needed. `PageRouteInfos` are now self-contained.

For more info read the complete migration guide
[Migrating to v9](https://github.com/Milad-Akarie/auto_route_library/blob/master/migrations/migrating_to_v9.md)

- **FIX**: Fix Aliased types are not generated correctly.
- **FEAT**: You can now create empty shell routes like follows:
  ```dart
     const BooksTab = EmptyShellRoute('BooksTab');
     context.push(BooksTab());
  ```

## 8.3.0

- **FEAT**: add url#fragment support.
- **FIX**: queryParams are not passed to child routes when matching by route name
- **FIX**: array query params are not parsed correctly.

## 8.2.0

- **FEAT**: migrate conditional import to js_interop.
- **FEAT**: update to web library.

## 8.1.4

- **FIX**: fix an error when popping a nested route after flutter 3.22.0 #1973.

## 8.1.3

- **FIX**: Fixed back gesture when nested navigator only has multi nested entries.
- **FIX**: Can not swipe back on iOS when using nested navigation #1932.

## 8.1.2

- **FIX**: Fixed back gesture when nested navigator only has one entry #1940

## 8.1.1

- **FIX**: Can not swipe back on iOS when using nested navigation #1932.

## 8.1.0

- **FEAT**: add deep-link transformer. Allows parsing the URI for deep links before the
  route matcher performs a match on the URI. Especially useful when you use intent-filter
  prefix on Android to only handle links from e.g com.example/FILTER.

  ```dart
  RouterConfig `<UrlState>` config({
  deepLinkTransformer : Deelkink.prefixStripper('FILTER'),
  )
  ```

  The resulting URI will be : com.example

## 8.0.2

- **FIX**: only disable parent back gesture if the active child can pop.
- **FIX**: AutoTabsRouterTabBarState was disposed with active Ticker #1910

## 8.0.1

- **FIX**: back-gesture does not respect sub-routes.

## 8.0.0

- **FEAT**: AutoTabsRouter will now use the declared routes if AutoTabsRouter.routes is not
  provided, if any of the tabs has required parameters it will throw an error.
- **BREAKING CHANGE**: deep-links with no host e.g scheme://page/sub-page are no longer
  automatically handled, flutter's deep-link handler will treat [page] as host so we end up
  with [/sub-page] as a path which of course not going to match. if your deep-links are hostless
  you'll need to handle them manually inside deepLinkTransformer or deepLinkBuilder.

## 7.9.2

- **HOTFIX**: fix an issue with deep-linking to tab-routes
- **CHORE**: remove deprecated apis

## 7.9.1

- **FIX**: incorrect top route information when deep-linking to an uninitialized tab route.

## 7.9.0

- **FIX**: unable to get the label for back button(previous route title) and current route title on
  CupertinoNavigationBar and CupertinoSliverNavigationBar #1795.
- **FIX**: CupertinoNavigationBar and CupertinoSliverNavigationBar unable to get route title and
  previous route title.
- **Fix**: PopScope.onPopInvoked not called when canPop is set to true,
- **Refactor**: rename router.pop to router.maybePop to avoid confusion
- **Refactor**: rename router.popTop to router.maybePopTop to avoid confusion
- **Refactor**: rename context.popRoute to context.maybePop

## 7.8.5

- **FEAT**: add back mixin to AutoRouteAware
- **FIX**: keep TabsRouter.homeIndex in sync with AutoTabsRouter.homeIndex

## 7.8.4

- **FIX**: Build Runner Efficiency Warning #1737
- **FIX**: ensure dynamic tab updates are handled in AutoTabsRouter.tabBar.
- **FEAT**: AutoRoute.copyWith

## 7.8.3

- **FIX**:

## 7.8.2

- **HOTFIX**: update sdk constrains to flutter: >=3.13.0 and dart: >=3.0.0 <4.0.0

## 7.8.1

- **FIX**: crash if pendingChildren are passed in as unmodifiable list.
- **DOCS**: Fix typos and a broken links.
- **REFACTOR**: remove usages of RouteInformation.location in favor of RouteInformation.uri

## 7.8.0

- **FEAT**: add PlatformDeepLink.initial flag to tell whether we're coming from setInitialRoutePath
  or setNewRoutePath.
- **FEAT**: add option to pass custom ignore_for_file rules to the generated file.
- **FEAT**: support the new allowSnapshotting flag.

## 7.7.1

- **FIX**: tab routes should be matched by key not name.

## 7.7.0

- **FEAT**: Add basic support to dart records.
- **FIX**: encoded path segments are not decoded in RouteMatch.pathParams
- **FIX**: encoded browser path is checked against a decoded matched path when deciding whether to
  replace route #1637

## 7.6.0

- **FEAT**: add 'scoped' argument to to StackRouter.removeUntil, if true the predicate will visit
  all StackRouters in hierarchy.
- **FEAT**: add 'scoped' argument to to StackRouter.popUntil, if true the predicate will visit all
  StackRouters in hierarchy.

## 7.5.0

- **FIX**: Uri percent-encoded characters encoded twice #1620.
- **FIX**: delegate missing arguments in auto_route_guard redirect.
- **FEAT**(auto_route): add `AutoPageRouteBuilder.opaque` argument.

## 7.4.0

- **FIX**: StackRouter.replaceAll does not work with nested tab-routes.
- **FEAT**: add optional flag to either update existing routes or not to StackRouter.replaceAll

## 7.3.2

- **FIX**: Remove guard from ActiveGuardObserver when resolved with false.

## 7.3.1

- **FIX**: DeferredWidget's default loader not working.
- **FEAT**: DeferredWidget will now take AutoRouterDelegate.placeholder value if provided

## 7.2.3

- **FEAT**: Add global guards reevaluate listenable
- **DOCS** Add reevaluate listenable docs to README.md
- **FEAT**: Add NavigationResolver.redirect method to auto-remove routes pushed by guards when
  resolving is complete
- **FEAT**: Add AutoRoute.guarded constructor for cleaner single guard implementation

## 7.2.0

- **FEAT**: add more flexible multi package support.
- **REFACTOR**: resolve some flutter 3.10 deprecations.
- **DOCS**(auto_route): fix typo.

## 7.1.0

- **FEAT**: add support to process files in micro-packages.

## 7.0.0

> Note: This release has breaking changes.

- **FIX**: deepLinkBuilder is not called on newRoutePath.
- **BREAKING** **CHANGE**: DefaultRouteParser.includePrefixMatches's value is now set to '!kIsWeb'
  instead of 'false'.
- **FEAT**: add rebuildStackOnDeepLink flag to rebuild the whole stack on incoming deep-links

## 6.4.0

- **REFACTOR**: deprecated initialDeepLink and initialRouts.
- **FEAT**: Added DeepLinkBuilder to validate or override platform deep-links
- **FEAT**: Added Route.data ext to get routeData of auto routes
- **DOCS**: Updated docs

## 6.3.0

- **FEAT**: Bring AutoRoute.initial back.

## 6.2.1

- **REFACTOR**: make AutoRouterState and AutoTabsRouterState public.

## 6.2.0

- Add public apis docs

# ChangeLog

## [6.1.0]

- The missing hierarchy to a pushed child-route will now be auto_created if there are no required
  args
- The root router can implement an AutoRouteGuard and guard all Stack-routes
- Add restorationId builder to AutoRoute
- Mark annotations with supported types [for static analysis]

## [6.0.5]

- Fix RouteMatch.fullPath is not joined properly
- Add helper method to get route match PageRouteInfo().match(context)

## [6.0.4]

- Fix inherited path params are not working in v6
- Add option to use cached_builds for more optimized generation

## [6.0.3]

- include merged pr's
- ## [6.0.2]
- Make AutoRoute.path call save

## [6.0.1]

- Fix bug with nested parent routes without path #1411

## [6.0.0+1]

- Use updated readme file

## [6.0.0]

- Fix secondAnimation value is always 0 in custom route transition

## [6.0.0-rc-7]

- Fix fullscreenDialog and maintainState flags are not passing to route data

## [6.0.0-rc-6]

- Fix topMostRouter is not always called on root-scope

## [6.0.0-rc-5] Breaking

- Fix but with new AutoTabsRouter.transition builder
- rename AutoRouteBuilder to auto_route_generator in build.yaml file to follow naming
  convention [breaking]

## [6.0.0-rc-4]

- Fix android back button closes App
- Add check for root routes must start with '/' or "*"

## [6.0.0-rc-3] Breaking

- Add transition builder to AutoTabsRouter and AutoTabsScaffold to only rebuild the body for
  animation and remove animation property from builder [breaking]
- Add router.currentHierarchy() helper method for debugging and testing.
- Add keepHistory flag to AutoRoute(), to remove route from stack on pushNext

## [6.0.0-rc-2]

- Fix CustomRoute.opaque not working

## [6.0.0-rc-1]

- Add path property to CustomRoute,CupertinoRoute and AdaptiveRoute
- Add functionality to push path states to browser history and read it

## [6.0.0-rc] Breaking

make sure you check
the [Migration guide](https://github.com/Milad-Akarie/auto_route_library/tree/v6.0.0_redesigned#migrating-to-v60)

- AutoRoute now takes a PageInfo object from the generated routes instead of Type
- Introduce @RoutePage() annotation to annotate routable widgets
- Routes are defined in the body of the router class instead of inside the annotation
- Remove replace @MaterialAutoRouter,@CupertinoAutoRouter ...etc with @AutoRouterConfig annotation
- Remove EmptyRouterPage & EmptyRouterScreen
- "initial" flag is removed now, use "/" for initial routes or empty path "" for nested-initial
  routes.
- Passing route guards is also changed now, instead of passing guards as types you now pass
  instances.
- Add title builder for AutoRoute(title: (ctx,data){})
- Docs are changed to reflect the new changes so make sure you re-read them.

---

## [5.0.4]

- Fix #1288

## [5.0.3]

- Fix redirect-route related issues
- Fix didChangeTabRoute not called when using AutoTabsRouter.tabBar()

## [5.0.2]

- Change analyzer constrains to support up to version 6.0.0
- Merge #1236
- Merge add opaque property to AdaptiveRoute #1224
- Merge readme.md file updates

## [5.0.1]

- Add ignorePagelessRoutes and ignoreChildRoutes property to AutoLeadingButton
- Add builder property to AutoLeadingButton
- Fix deferredLoading and AutoRouteWrapper are not working together

## [5.0.0]

- Add deferred loading support for web to enable code splitting for routes [By Garzas]
- Move EmptyRouterScreen and EmptyRouterPage to a separate file to avoid import conflict when using
  deferred loading.
- Fix a bug in Navigation History
- Add License file to root package
- Fix TabController dispose issue in AutoTabsRouter.tabBar
- Add neglectWhen call back to ignore reporting location to engine
- Remove universal_html dependency and implement own conditional html import

## [4.2.1]

- Fix AutoTabsRouter animation controller is disposed after super.dispose()
- merge readme fixes

## [4.2.0]

- Add generate-time check for unresolvable path params
- You can now access inherited path params using @pathParam annotation

## [4.1.0]

- Upgrade minimum Flutter SDK to 3.0.0
- Upgrade minimum Dart SDK to 2.17.0
- Fix PageView tabs implementation non-neighbor transition issue
- Add scroll physics and dragStart behavior to booth tabBar nad pageView implementations

## [4.0.1]

- Fix incompatibility issues with flutter 3.0.0
- fix reverseDurationInMilliseconds not being generated from router config

## [4.0.0] (Breaking changes)

- Refactor AutoRedirectGuard [Breaking Change]
- Add AutoRouteAwareStateMixin to minimize boilerplate for AutoRouteAware states
- Add NoShadowCupertinoTransitionsBuilder to remove unwanted shadow in nested cupertino routes
- Add PageView support to AutoTabsRouter
- Add TabBar support to AutoTabsRouter
- Add custom builder support to AutoTabsRouter
- Remove AutoTabsRouter.declarative implementation (replaced with builder) [Breaking Change]
- AutoRouter.declarative routes now accepts a PendingRoutesHandler instead of
  context [Breaking Change]
- Fix wrapped routes are rebuilt everytime the stack changes
- Fix query params are not updated in Tab-Routes
- Add router.activeGuardObserver to access active guards. e.g to implement loading indicator
- Fix initial route is not showing when nested router is rebuilt
- Replace AutoBackButton with AutoLeadingButton to support drawer and close icons

## [3.2.4]

- Fix path/query params are not updated in url when navigating to the same current path #854 #944

## [3.2.3+1]

- Remove forgotten print statement

## [3.2.3]

- Fix routes with empty path don't update url #960
- Fix RouteInformationProvider.routerReportsNewRouteInformation required 'type' issue #958

## [3.2.2]

-Add removeAllAndPush route strategy to auto_redirect_route

## [3.2.1]

- Merge some readme file typo-fixes
- Add @optionalTypeArgs to AutoRoute annotations
- Fix AdaptiveRoute issue with CustomRoute
- Change analyzer constrains to include version 3.0.0
- Add notify flag to removeWhere method inside of StackRouter

## [3.2.0]

- Merge fix conform new API in Flutter 2.6
- Fix declarative routes update issue
- Add Router tests

## [3.1.3]

- Fix navigateNamedTo does not update the stack #831
- Refactor navigation history and set kept history records to 20 entries max

## [3.1.2]

- Fix Bad state: No element exception when setting initialRoutes #826
- Fix conflict when param name is 'name' #824

## [3.1.1]

- Fix Regression bug (caused by immutable pendingRoutes list) #822

## [3.1.0]

- Prefer previous-current route index as new current index when updating tab routes #797
- Improve native navigation history
- Use browser history as navigation history in web
- Fix path/query params not updating issue #809
- Fix generic nullable types are generated as non-nullables #811
- Override toString method inside of generated arg classes [FR] #820
- Support redirect paths with path params [FR] #818
- Fix replace/replaceNamed/replaceAll do not replace current url in browser #781

## [3.0.4]

- Fix IndexedStack widgets are not updated on tabs routes change.
- Fix RangeError when updating routes in AutoTabsScaffold #788

## [3.0.3]

- Fix dynamic routes for AutoTabsScaffold don't work #783

## [3.0.2]

- Make AutoTabsScaffold builders rebuild on global routes hierarchy changes

## [3.0.1]

- Fix conflict with source_gen:combining_builder by using .gr.dart instead of .g.dart

## [3.0.0]

- Add option to use part builder .g.dart
- Add option to pass const meta data from annotation to consumed route data.
- Show better error message when router can not navigate to given route.
- ancestor router can now push directly to nested router if it's already in stack.
- Add navigateBack functionality
- Add AutoRedirectRoute which reevaluates guarded routes that's already in stack

## [2.4.2]

- Add fullscreenDialog flag to pushWidget method
- Add pushNativeRoute method

## [2.4.1]

- Fix pushing same route not rebuilding stack; effecting #717 #710
- Fix dialogs/bottom sheets don't play nicely with auto_route when using nested routers
- Add option to push an un-routable widgets to StackRouters
- Add a comment containing the widget type reference to generated routes for easy source jumping

## [2.4.0]

- Fix url updates delay
- Fix navigate does not update url
- Add auto_route_information_provider.dart to fix infinite browser back button when using url
  redirects
- optimize routes rebuild -> only rebuild if route data changes
- Change routers are now not ( Watched ) by default to reduce rebuilds [ may Break]
- Add optional homeIndex property to AutoTabsRouter to make sure we always pop from home tab
- Change AutoBackButton to use StackRouterScope instead of RouterScope

## [2.3.2]

- Merge fix(generator): Bool opt type as num #688
- Fix nested back gesture issue #686

## [2.3.1]

- Fix navigate to nested routes open last visited nested route #676
- Add pop parent route support in AutoBackButton

## [2.3.0]

- Fix crash when passing non-string values as query params #606
- Update analyzer version to 2.0.0
- Update build_runner,build and source_gen versions
- Merge #616 Export navigation failure
- Merge #550 Enable AutoTabsScaffold to support custom appbar [Breaking]
- Update README file

## [2.2.1]

- Fix crash when passing non-string values as query params #606
- Update analyzer version to 2.0.0
- Update build_runner,build and source_gen versions

## [2.2.0] Breaking changes!

- Remove helper methods pushToChild and replaceInChild from TabsRouter [Bad idea]. [Breaking]
- Add navigate and navigateNamed methods to TabsRouter
- Add navigateNamedTo method to context extension
- Change context.navigateTo and context.navigateNamedTo will be fired
  by nearest RouterScope weather it's a StackRouter or a TabsRouter
- Fix AutoRouteGuard is not fired when route is updating #517
- Fix DidInitTabRoute method is fired when a route is pushed in AutoRouteAware widgets #518

## [2.1.1] Breaking changes!

- AutoRouteGuard's canNavigate method is now called onNavigation. [Breaking]
- Add AutoRouteObserver to add support tab route observing.

## [2.1.0] Breaking changes!

- AutoRouteGuard no longer returns a future`<bool>` and passes in a resolver. [Breaking]
- Remove onInitialRoutes from AutoRouterDelegate. [Breaking]
- Rename RoutingControllerScope to RouterScope. [Breaking]
- Expose provided navigatorObservers in RouterScope
- Route name is now default page key with option to use path as key.
- Add onNavigate callback function to AutoRouterDelegate
- Add onNavigate all back to AutoRouter.declarative
- Add declarative option to AutoTabsRouter

## [2.0.1] Breaking changes!

- OnPopRoute includes a results object now. [Breaking]
- Remove usesTabsRouter property from AutoRoute as it's no longer needed.
- Required queryParams to either be nullable or have a default value

## [2.0.0] Breaking changes!

##### breaking changes

- Remove usesTabsRouter property from AutoRoute as it's no longer needed.
- onGenerateRoutes is now shortened to just routes and initial routes are no longer pass
- Legacy generator is completely dropped now.
- navigatorObservers is not a callback function that returns a list of observers

##### enhancements

- Bring back the good old await for pop results feature.
- The root AutoRouterDelegate can now be declarative.
- Push, replace and navigate will now bubble up if they can't be handled by the router they're
  called from.
- Enhance the navigate function to behave like navigating from the browser's bar.
- Add new methods to navigate by path pushNamed, replaceNamed and navigateNamed.
- Add AutoBackButton to handle nested routers popping with ease.
- Add some helper/shortcut methods to context extension, pushRoute, replaceRoute, navigateTo and
  popRoute.
- Add some helper methods to the RoutingController like popTop, topRoute and more.
- Pages will rebuild when an ancestor router updates if you depend on it.
- Add Auto RedirectRoute generation for Routes with none initial paths that's marked as initial.
- Add AutoRouteObserver to add tabs observing to the native observer.
- NavigatorObservers are now passed through a builder so nested navigators can inherit them.
- Add HeroControllerScope to nested AutoRouters
- Pomp up code_builder version to 4.0.0 and build_runner to 2.0.1
- Fix #458, #456 #421 and #453
- Minor fixes and enhancements

## [1.0.2]

- Pomp up versions of build, build_runner, dart_style and source_gen
- Using pathParam annotation is not more flexible and has less constrains
- Remove dart:io import to include (web) as a supported platform
- other fixes

## [1.0.1]

- Fix Stack overflow in RootStackRouter popUntilRoot() #401
- Fix path parameters are assigned an undefined var when alias is different than param name.

## [1.0.0]

- Migrate to null-safety
- Add option to pass restoration id
- Add option to specify the root navigator background color

## [1.0.0-beta.10]

- Fix generic parameters crash the generator
- Add support for array type query params

## [1.0.0-beta.9]

- Fix navigatorKey state is lost on hot reload
- Add stackRouterOfIndex getter function to AutoTabsRouter

## [1.0.0-beta.8]

- Add support for null-Safety to generated code.
- Fix pop issues
- Add popUntil, popUntilRoot and popUntilRouteWithName helper functions to StackRouter
- Minor fixes
  Edit [BC] pushAndPopUntil uses the native predicate now.

## [1.0.0-beta.7]

- Fix onRoutePop not called in declarative router #310
- Fix App reloads after pressing browser's back button #309
- Fix TabsRouter not displaying current route when pressing the browser's back button
- Add pop until method to StackRouter
- Prefix parent routes are now included if includePrefixMatches is true
- Add RouteMatcher tests
- Minor improvements

## [1.0.0-beta.6]

- Fix reload issue when pressing the browser's back button #309
- Fix onPopRoute is not called in declarative Router #310
- Include empty paths as prefix-matched paths when deep-linking.
- Remove unnecessary dependencies
- Some minor improvements and code refactor

## [1.0.0-beta.5]

- Refactor some code
- Update readme file

## [1.0.0-beta.4]

- Fix page can not be used for multiple routes
- Add duplicate route-names check in generator.

## [1.0.0-beta.3+1]

- Fix badge alignment in readme file

## [1.0.0-beta.3]

- Fix crash on empty path deep-linking
- Fix parent does not take priority when child can't pop
- Change includePrefixMatches default value to false in DefaultRouteParser
- Add some updates to Readme file

## [1.0.0-beta.2]

- Add lazyLoad option to AutoTabsRouter
- Replace AutoRouterConfig with an implementation of StackRouter
- Root delegate is now lazyLoaded

## [1.0.0-beta.1] Breaking Changes!

- Add TabsAutoRouter
- Refactor some code

## [1.0.0-beta] Breaking Changes!

- Rebuild auto_route to work with Navigator 2.0

---

## [0.6.9]

- Fix generator error running flutter version 1.22
- Fix bar-url not updated in flutter version 1.22

## [0.6.7]

- Fix blue screen issue when using guards on initial route #189
- Fix relative import issues
- Add option to not prefer relative imports
- Fix some linter warnings
- Fix issue #176

## [0.6.6]

- Fix hot reload issue #170
- Fix Hero animations not working with the new ExtendedNavigator # 169
- Add static builder to ExtendedNavigator to use with MaterialApp's builder

## [0.6.5]

- Downgrade path package to >= 1.6.4 to solve conflict with flutter_test
- Clean up auto_route index file

## [0.6.4]

- Add usage of const constructors when possible
- Fix material package is only imported if needed
- Fix spelling mistakes in changeLog

## [0.6.2] Breaking Change

- Fix deep linking issue for nested routes
- Change ExtendedNavigator to wrap the native navigator instead of extending it
- Change generated class applies to most of effective dart rules including preferring relative
  imports
- Change initial route placeholder color to white
- Add extension to BuildContext to easily access the navigator
- Remove NestedNavigator, ExtendedNavigator can be used directly as a nested navigator
- Rename some properties and deprecate their older names
- Remove ExtendedNavigator.ofRouter method
- Minor fixes and enhancements

## [0.6.1]

- Fix pop until name issue by implementing PopUntilPath and RouteData.withPath
- Fix opening deep links in new tabs pushes initial route only

## [0.6.0+1]

- Fix README file links

## [0.6.0] Breaking Change

- Change the way routes are declared from class fields to a static list
- Add support for path & query parameters
- Add support for path wildcards
- Add support for nested routes
- Add support for generic result types
- Add a get ExtendedNavigator by name feature
- Merge a fix for adaptive route web support issue
- Change generating arguments holder for single parameter routes is not optional anymore
- Minor fixes and enhancements

## [0.5.0]

- Add allRoutes getter to RouterBase
- minor fixes

## [0.4.6] Skip

## [0.4.5] Breaking Change

- Add AdaptiveAutoRouter and AdaptiveRoute for native platforms
- Change using leading slashes is now options
- Change wrappedRoute is now a function that takes in build context
- Fix calling nested route returns null after popping parent route
- Fix initial route ignore custom transitions
- Add ability to name routes class

## [0.4.4]

- Change generating arguments holder for single parameter routes is not optional
- Fix android soft back button always pops root navigator

## [0.4.3] Breaking Changes

- Add ability to pass initial route arguments to ExtendedNavigator
- Change single route parameters will have argument holder classes too as requested
- Fix ExtendedNavigator.ofRouter`<T>`() returns null in inspector mode

## [0.4.2]

- Fix Android soft back button always exists App

## [0.4.1] Breaking Changes

- Fix isInitialRoute not defined for RouteSettings in flutter 1.15.+

## [0.4.0] Breaking Changes

- Change using ExtendedNavigator instead of the native Navigator
- Fix initial route does not go through guards
- Change generated router class is no longer static
- Change routes are generated in their own class now "Routers"
- Add option to generate navigation helper methods extension
- Update README file

## [0.3.1]

- Fix Compilation Fails in flutter 1.15.+
- Fix third party imports src instead of library
- Fix guardedRoutes is generated even if it's empty
- Add support for custom unknown route screen

## [0.3.0] Breaking Changes!

- Add global route customization
- Use MaterialAutoRouter, CupertinoAutoRouter or CustomAutoRouter instead of AutoRouter
- Navigator key is now accessed by calling Router.navigator.key instead of Router.navigatorKey.
- Add Route guards
- Add optional returnType param in all AutoRoute types.
- Remove generate Navigator Key optional.
- Fix generate error when using dynamic vars in route widget constructors

## [0.2.2]

- Add option to generate a list with all route names
- change generating navigator key is now optional
- Fix prevent importing system library files
- Change generated route path name are now Kabab cased (url-friendly)
- Add ability to use custom path names in all route types
- Update README file

## [0.2.1]

- add Route Wrapper
- add initial flag as a property in all route types
- change prefix const route names with class name.
- add fullscreenDialog property to @CustomRoute()

## [0.2.0+1]

- format README file

## [0.2.0]

### Breaking Changes!

- change to using a single config file instead of annotating the actual widget class due to
  performance issues.
- add @MaterialRoute(), @CupertinoRoute() and @CustomRoute() annotations
- remove @AutoRoute() annotation and add @AutoRouter()
- handle required parameters.
- add navigating with a global navigator key [without context].
- support nested navigators.

## [0.1.1]

- code formatting.

## [0.1.0]

- initial release.
