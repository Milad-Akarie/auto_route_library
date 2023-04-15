# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

