# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-10-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v10.2.0`](#auto_route---v1020)
 - [`auto_route_generator` - `v10.2.5`](#auto_route_generator---v1025)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v10.2.5`

---

#### `auto_route` - `v10.2.0`

 - **REFACTOR**: update element references and improve method signatures for clarity.
 - **REFACTOR**: remove redundant formatting in generated code.
 - **REFACTOR**: Improve tab navigation and observer logic.
 - **FIX**: respect page.opaque for transparent route.
 - **FIX**: meta import.
 - **FIX**: Allow PopCompleter to complete during route reevaluation.
 - **FIX**(reevaluate): ensure _isReevaluating is reset after reevaluation.
 - **FIX**: improve focus and semantics handling in AutoTabsRouter.
 - **FIX**: default argsEquality to true for route args and update related documentation.
 - **FIX**: respect argsEquality config in PageRouteInfo == operator.
 - **FIX**: Generated code is not properly formatted.
 - **FEAT**: Add experimental support for lean_builder.
 - **FEAT**: expose routeTraversalEdgeBehavior.
 - **DOCS**: improve LeanBuilder section in README.
 - **DOCS**: improve LeanBuilder section in README.


## 2025-03-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v10.0.1`](#auto_route---v1001)
 - [`auto_route_generator` - `v10.0.2`](#auto_route_generator---v1002)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v10.0.2`

---

#### `auto_route` - `v10.0.1`

 - **REFACTOR**(custom_route): update route duration type from int to Duration.
 - **FIX**: guard reevaluation issues  #1993 #2151 #2100.
 - **FIX**: Exposing clipBehavior for nested navigation #2082.
 - **FIX**: When use AutoTabsRouter.tabBar, maintainState: false and TabBar together, fails to load routes in some cases #2113.
 - **FIX**: Unexpected null value issue with context in provider model and AutoRouteGuard #1707.
 - **FIX**: Unexpected null value issue with context in provider model and AutoRouteGuard #1707.


## 2024-08-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v9.2.1`](#auto_route---v921)
 - [`auto_route_generator` - `v9.0.1`](#auto_route_generator---v901)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v9.0.1`

---

#### `auto_route` - `v9.2.1`

 - **FIX**: revert web package back to version ^0.5.1 because it's pinned in a lot of other packages.


## 2024-08-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v9.2.0`](#auto_route---v920)
 - [`auto_route_generator` - `v9.0.1`](#auto_route_generator---v901)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v9.0.1`

---

#### `auto_route` - `v9.2.0`

 - **FIX**: revert web package back to version ^0.5.1 because it's pinned in a lot of other packages.
 - **FIX**: revert web package back to version ^0.5.1 because it's pinned in a lot of other packages.
 - **FEAT**: Add query params options to redirectTo in RedirectRoute #1721.
 - **FEAT**: Add query params options to redirectTo in RedirectRoute #1721.


## 2024-07-31

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v9.1.0`](#auto_route---v910)
 - [`auto_route_generator` - `v9.0.1`](#auto_route_generator---v901)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v9.0.1`

---

#### `auto_route` - `v9.1.0`

 - **FEAT**: Add query params options to redirectTo in RedirectRoute #1721.


## 2024-07-31

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v9.0.1`](#auto_route---v901)
 - [`auto_route_generator` - `v9.0.1`](#auto_route_generator---v901)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v9.0.1`

---

#### `auto_route` - `v9.0.1`

 - **FIX**: make EmptyShellRoute() a const.


## 2024-07-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.3.0`](#auto_route---v830)
 - [`auto_route_generator` - `v8.1.0`](#auto_route_generator---v810)

---

#### `auto_route` - `v8.3.0`

 - **FEAT**: add url#fragment support.

#### `auto_route_generator` - `v8.1.0`

 - **FEAT**: add url#fragment support.


## 2024-06-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.2.0`](#auto_route---v820)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.2.0`

 - **FEAT**: migrate conditional import to js_interop.
 - **FEAT**: update to web library.


## 2024-06-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.1.4`](#auto_route---v814)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.1.4`

 - **FIX**: fix an error when popping a nested route after flutter 3.22.0 #1973.


## 2024-04-26

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.1.3`](#auto_route---v813)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.1.3`

 - **FIX**: Fixed back gesture when nested navigator only has multi nested entries.
 - **FIX**: Can not swipe back on iOS when using nested navigation #1932.


## 2024-04-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.1.1`](#auto_route---v811)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.1.1`

 - **FIX**: Can not swipe back on iOS when using nested navigation #1932.


## 2024-03-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.0.2`](#auto_route---v802)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.0.2`

 - **FIX**: only disable parent back gesture if the active child can pop.


## 2024-03-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v8.0.1`](#auto_route---v801)
 - [`auto_route_generator` - `v8.0.1`](#auto_route_generator---v801)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v8.0.1`

---

#### `auto_route` - `v8.0.1`

 - **FIX**: back-gesture does not respect sub-routes.


## 2024-03-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.10.0`](#auto_route---v7100)
 - [`auto_route_generator` - `v7.3.3`](#auto_route_generator---v733)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.3.3`

---

#### `auto_route` - `v7.10.0`

 - **FEAT**: AutoTabsRouter will now use the declared routes if AutoTabsRouter.routes is not provided.


## 2024-03-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.9.1`](#auto_route---v791)
 - [`auto_route_generator` - `v7.3.3`](#auto_route_generator---v733)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.3.3`

---

#### `auto_route` - `v7.9.1`

 - **FIX**: incorrect top route information when deep-linking into an uninitialized tab route.


## 2024-03-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.9.0`](#auto_route---v790)
 - [`auto_route_generator` - `v7.3.3`](#auto_route_generator---v733)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.3.3`

---

#### `auto_route` - `v7.9.0`

 - **REFACTOR**(example): remove unnecessary pageTransitionsTheme parameter.
 - **FIX**: unable to get the label for back button(previous route title) and current route title on CupertinoNavigationBar and CupertinoSliverNavigationBar #1795.
 - **FIX**: CupertinoNavigationBar and CupertinoSliverNavigationBar unable to get route title and previous route title.
 - **FIX**: docstring typo(RouteData.mete -> RouteData.meta).
 - **FIX**: keep TabsRouter.homeIndex in sync with AutoTabsRouter.homeIndex.
 - **FEAT**: add back mixin to AutoRouteAware.


## 2023-10-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.8.4`](#auto_route---v784)
 - [`auto_route_generator` - `v7.3.2`](#auto_route_generator---v732)

---

#### `auto_route` - `v7.8.4`

 - **FIX**: ensure dynamic tab updates are handled in AutoTabsRouter.tabBar.
 - **FIX**: issue related to parsing deep-links after flutter 3.13.0.

#### `auto_route_generator` - `v7.3.2`

 - **DOCS**: Add public Api docs to auto_route_generator.


## 2023-08-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.8.2`](#auto_route---v782)
 - [`auto_route_generator` - `v7.3.2`](#auto_route_generator---v732)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.3.2`

---

#### `auto_route` - `v7.8.2`

 - **DOCS**: Fix typos and a broken links.


## 2023-08-22

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.8.1`](#auto_route---v781)
 - [`auto_route_generator` - `v7.3.2`](#auto_route_generator---v732)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.3.2`

---

#### `auto_route` - `v7.8.1`

 - **FIX**: crash if pendingChildren are passed in as unmodifiable list.
 - **DOCS**: Fix typos and a broken links.
 - **DOCS**: Add public Api docs to auto_route_generator.


## 2023-08-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.3.1`](#auto_route_generator---v731)

---

#### `auto_route_generator` - `v7.3.1`

 - **DOCS**: Add public Api docs to auto_route_generator.


## 2023-08-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.8.0`](#auto_route---v780)
 - [`auto_route_generator` - `v7.3.0`](#auto_route_generator---v730)

---

#### `auto_route` - `v7.8.0`

 - **FEAT**: add PlatformDeepLink.initial flag to tell whether we're coming from setInitialRoutePath or setNewRoutePath.
 - **FEAT**: add option to pass custom ignore_for_file rules to the generated file.
 - **FEAT**: support the new allowSnapshotting flag.

#### `auto_route_generator` - `v7.3.0`

 - **REFACTOR**: generated routes are not alphabetically sorted.
 - **FEAT**: add option to pass custom ignore_for_file rules to the generated file.
 - **FEAT**: Add basic support to dart records.


## 2023-07-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.7.1`](#auto_route---v771)
 - [`auto_route_generator` - `v7.2.1`](#auto_route_generator---v721)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.2.1`

---

#### `auto_route` - `v7.7.1`

 - **FIX**: tab routes should be matched by key not name.


## 2023-07-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.7.0`](#auto_route---v770)
 - [`auto_route_generator` - `v7.2.0`](#auto_route_generator---v720)

---

#### `auto_route` - `v7.7.0`

 - **FEAT**: Add basic support to dart records.

#### `auto_route_generator` - `v7.2.0`

 - **FEAT**: Add basic support to dart records.


## 2023-07-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.2.0`](#auto_route_generator---v720)

---

#### `auto_route_generator` - `v7.2.0`

 - **FEAT**: add 'scoped' argument to to StackRouter.popUntil, if true the predicate will visit all StackRouters in hierarchy.
 - **DOCS**: update CHANGELOG.md.


## 2023-07-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.6.0`](#auto_route---v760)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.6.0`

 - **FEAT**: add 'scoped' argument to to StackRouter.removeUntil, if true the predicate will visit all StackRouters in hierarchy.
 - **FEAT**: add 'scoped' argument to to StackRouter.popUntil, if true the predicate will visit all StackRouters in hierarchy.


## 2023-06-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.5.0`](#auto_route---v750)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.5.0`

 - **FIX**: Uri percent-encoded characters encoded twice #1620.
 - **FIX**: delegate missing arguments in auto_route_guard redirect.
 - **FEAT**(auto_route): add `AutoPageRouteBuilder.opaque` argument.


## 2023-06-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.3.3`](#auto_route---v733)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.3.3`

 - **FIX**: StackRouter.replaceAll does not work with nested tab-routes.


## 2023-05-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.3.2`](#auto_route---v732)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.3.2`

 - **FIX**: Remove guard from ActiveGuardObserver when resolved with false.


## 2023-05-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.3.1`](#auto_route---v731)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.3.1`

 - **FIX**: DeferredWidget's default loader not working,.


## 2023-05-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.1.1`](#auto_route_generator---v711)

---

#### `auto_route_generator` - `v7.1.1`

 - **REFACTOR**: change module extension from .module.dart to .gm.dart.
 - **DOCS**: update CHANGELOG.md.


## 2023-05-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.2.0`](#auto_route---v720)
 - [`auto_route_generator` - `v7.1.0`](#auto_route_generator---v710)

---

#### `auto_route` - `v7.2.0`

 - **REVERT**: "feat: add more flexible multi package support".
 - **REFACTOR**: resolve some flutter 3.10 deprecations.
 - **FEAT**(auto_route): add `AutoRouterConfig.module` annotation.
 - **FEAT**(auto_route): add `AutoRouterModule`.
 - **FEAT**: add more flexible multi package support.
 - **DOCS**(auto_route): fix typo.

#### `auto_route_generator` - `v7.1.0`

 - **REVERT**: "feat: add more flexible multi package support".
 - **REVERT**: "cleanup".
 - **FEAT**(auto_route_generator): expose the new `autoRouterModuleBuilder` to the package surface.
 - **FEAT**(auto_route_generator): add `AutoRouterModuleBuilder`.
 - **FEAT**(auto_route_generator): update code builder (add module support + rename).
 - **FEAT**(auto_route_generator): update `RouterConfig` + `RouterConfigResolver` to match `AutoRouterConfig.module`.
 - **FEAT**: add more flexible multi package support.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.0.0`](#auto_route_generator---v700)

---

#### `auto_route_generator` - `v7.0.0`

 - **FEAT**: add support to process files in micro-packages.
 - **DOCS**: add all public api docs.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.1.0`](#auto_route---v710)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v7.1.0`

 - **FEAT**: add support to process files in micro-packages.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - [`auto_route` - `v7.0.0`](#auto_route---v700)

Packages with other changes:

 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v7.0.0`

 - **FIX**: deepLinkBuilder is not called on newRoutePath.
 - **BREAKING** **CHANGE**: DefaultRouteParser.includePrefixMatches's value is now set to '!kIsWeb' instead of 'false'.


## 2023-04-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.4.0`](#auto_route---v640)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.4.0`

 - **REFACTOR**: deprecated initialDeepLink and initialRouts.


## 2023-04-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.3.0`](#auto_route---v630)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.3.0`

 - **REFACTOR**: make AutoRouterState and AutoTabsRouterState public.
 - **FEAT**: Bring AutoRoute.initial back.


## 2023-04-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.2.1`](#auto_route---v621)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.2.1`

 - **REFACTOR**: make AutoRouterState and AutoTabsRouterState public.
 - **DOCS**: add all public api docs.


## 2023-04-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.2.0`](#auto_route---v620)
 - [`auto_route_generator` - `v6.2.0`](#auto_route_generator---v620)

---

#### `auto_route` - `v6.2.0`

 - **FIX**: need to always depend on RouterScope.
 - **FIX**: url state decode issue.
 - **FEAT**: Add a getter to expose child widget from AutoRoutePage.
 - **FEAT**: deferred loading for web to enable code splitting for routes.

#### `auto_route_generator` - `v6.2.0`

 - **FIX**: include nested pages imports.
 - **FIX**(generator): Bool opt type as num.
 - **FEAT**: deferred loading for web to enable code splitting for routes.

