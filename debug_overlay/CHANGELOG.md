# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- Template:
## NEW · YYYY-MM-DD

### ⚠️ BREAKING CHANGES
### 🎉 New Features
### ⚡ Changes
### 🐛 Bug Fixes
### 📜 Documentation updates
### 🏗️ Refactoring
### 📦 Build & CI
-->

## 3.0.1 · 2026-11-17

### 📜 Documentation updates

- Link directly to Pub sites of companion packages ([`3ebcaed`](https://github.com/JonasWanke/debug_overlay/commit/3ebcaed22dae7fc00099464a73f49051c869c137))

## 3.0.0 · 2026-11-17

### ⚠️ BREAKING CHANGES

- replace the `DebugHelper` widgets with `DebugTool`s, which are `ChangeNotifier`s instead of widgets ([`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
  - remove `DebugHelper`; custom helpers (previously any `Widget` in the list) now extend `DebugTool` and implement `buildSliver` (see the README)
  - rename `*DebugHelper` to `*DebugTool`, e.g., `LogsDebugHelper(logs)` -> `LogsDebugTool(logs)`; they're no longer widgets, so the `key` parameters are gone ([`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
  - replace the `DiagnosticsBasedDebugHelper` widget, which took a `title` and a `diagnosticsStream`, with the abstract `DiagnosticsBasedDebugTool`; extend it and implement `diagnosticsStream(context)` ([`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
  - rename `DebugOverlay.helpers`, `prependHelper`, and `appendHelper` to `tools`, `prependTool`, and `appendTool` ([`50ab1ec`](https://github.com/JonasWanke/debug_overlay/commit/50ab1eca5637d2a79f06f4c5c27a64c65b505a97))
  - replace `DebugOverlay.show()` and `hide()` with `expand()` and `close()` ([`f6da7f5`](https://github.com/JonasWanke/debug_overlay/commit/f6da7f5df54fddad64aa7aaddb746e8e924a8d58))
  - remove `DebugOverlayState`, `DebugOverlayContent`, `LogEntryWidget`, and `DiagnosticLevelSelector` from the public API ([`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
- move tools with additional dependencies into separate packages in a pub workspace ([`e62ae00`](https://github.com/JonasWanke/debug_overlay/commit/e62ae0018b482249b3a186af292584013ee0c354), [`0a22073`](https://github.com/JonasWanke/debug_overlay/commit/0a22073466b212f1629a56dbe52044ae5ff98522))
  - `DeviceInfoDebugHelper` -> `DeviceInfoDebugTool` in `debug_overlay_device_info_plus`
  - `PackageInfoDebugHelper` -> `PackageInfoDebugTool` in `debug_overlay_package_info_plus`
  - `DebugOverlay.tools` no longer contains them by default; add them via `DebugOverlay.appendTool(...)`

### 🎉 New Features

- add a collapsed mode that shows a draggable bubble; dragging the sheet down collapses it, and dropping the bubble onto the dismiss target closes the overlay ([`f6da7f5`](https://github.com/JonasWanke/debug_overlay/commit/f6da7f5df54fddad64aa7aaddb746e8e924a8d58), [`c3e665a`](https://github.com/JonasWanke/debug_overlay/commit/c3e665ac81e785575f34dc56978795b3f927339c))
  - control the overlay via `DebugOverlay.mode` (`DebugOverlayMode`), `expand()`, `collapse()`, and `close()`
- add `DebugOverlayTrigger` to open the overlay with a two-finger hold or <kbd>Alt</kbd> + <kbd>F12</kbd>; configure it via `DebugOverlay.builder(trigger: ...)` ([`f6da7f5`](https://github.com/JonasWanke/debug_overlay/commit/f6da7f5df54fddad64aa7aaddb746e8e924a8d58))
- add `RenderingDebugTool` ([`edc187a`](https://github.com/JonasWanke/debug_overlay/commit/edc187ae9d37fae7a40ff00b95107b7011312faf))
- add `NetworkDebugTool` and `NetworkRequestCollection`, with `debug_overlay_http` and `debug_overlay_dio` to record requests ([`909d94c`](https://github.com/JonasWanke/debug_overlay/commit/909d94c55ae8c364eb9dc7f7f0e36437e30f886a), [`80a55d9`](https://github.com/JonasWanke/debug_overlay/commit/80a55d908bf7630d386e14df19a946153fb3088e))
- add `debug_overlay_shared_preferences` with `SharedPreferencesDebugTool` ([`7a954ad`](https://github.com/JonasWanke/debug_overlay/commit/7a954ad55dfaef13b59065b47cf4051d9e05a8a0))
- add `debug_overlay_file_browser` with `FileBrowserDebugTool` ([`eac8b12`](https://github.com/JonasWanke/debug_overlay/commit/eac8b1235850c3d0b096f0fc92f1f3fc4add6438))
- add a search field for logs, network requests, diagnostics-based tools, shared preferences, and files; custom tools opt in via `DebugTool.isSearchable` and `matchesSearch` ([`f5259c4`](https://github.com/JonasWanke/debug_overlay/commit/f5259c4840c02534bb1fe9de25b7f40e84128cc6))

### ⚡ Changes

- show one tool at a time instead of all helpers in a single list; a header with the active tool's title opens a grid to switch tools, and a tool's actions appear in that header ([`50ab1ec`](https://github.com/JonasWanke/debug_overlay/commit/50ab1eca5637d2a79f06f4c5c27a64c65b505a97), [`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
- tool state (filters, sort order, and so on) survives switching tools and closing the overlay ([`59805b1`](https://github.com/JonasWanke/debug_overlay/commit/59805b16043925757a6912bc06f3c75a94193ce3))
- update to Flutter `>=3.50.0` and Dart `^3.14.0` ([`0d54d1f`](https://github.com/JonasWanke/debug_overlay/commit/0d54d1f77a8be23074a18758352bd5450c9994b5))

### 🐛 Bug Fixes

- `LogCollection.maximumSize`: the setter didn't store the new value ([`82a9fd7`](https://github.com/JonasWanke/debug_overlay/commit/82a9fd7a510763074157ec93a82bef755c1c5f11))

## 2.0.0 · 2026-08-26

### ⚠️ BREAKING CHANGES

- remove shake-to-open support ([`ce6c9c2`](https://github.com/JonasWanke/debug_overlay/commit/ce6c9c2cf55d2736685b94ca6363c741b44bfaae))
  - `shake_detector` uses very outdated dependencies and doesn't support all platforms. You can still implement your own shake-to-open logic.
  - drop the `shake_detector` dependency
  - remove `DebugOverlay`'s/`DebugOverlay.builder`'s `showOnShake` and `createShakeDetector` parameters — call `DebugOverlay.show()` to open the overlay instead

### ⚡ Changes

- `MediaQueryDebugHelper`: show `textScaler` instead of the deprecated `textScaleFactor` ([`1f50a7e`](https://github.com/JonasWanke/debug_overlay/commit/1f50a7e9f189f0224c9ee634a2a3cf3f9fbb6a9a))

### 🐛 Bug Fixes

- add missing string to `FlagProperty` for `enableOnlyInDebugMode` ([`a8c1655`](https://github.com/JonasWanke/debug_overlay/commit/a8c165561053a994140e9547ed0d1b0adf5a1bac))

### 📦 Build & CI

- update to Flutter `>=3.47.0` and Dart `^3.13.0` ([`7796d5e`](https://github.com/JonasWanke/debug_overlay/commit/7796d5e437d84896ef5f503b7b8ffeff936b8084), [`db72472`](https://github.com/JonasWanke/debug_overlay/commit/db72472341cf23258dffa08faa9cf50f0c9befba))
- update `device_info_plus` to `^13.0.0`, `package_info_plus` to `^10.0.0` ([`e342c0d`](https://github.com/JonasWanke/debug_overlay/commit/e342c0d3986f71c003303aa6c2f95d2ecc8a2ae8))
- update `supernova_lints` and use dot-shorthands & primary constructors throughout ([`540a976`](https://github.com/JonasWanke/debug_overlay/commit/540a97627b202d78562555abe0d58c93382b5157), [`1bf689e`](https://github.com/JonasWanke/debug_overlay/commit/1bf689e0d4253d19aad750936c7c6e97f53e33e2), [`74d9de7`](https://github.com/JonasWanke/debug_overlay/commit/74d9de78ca82420ad82ccfc113c1067053062db8))
- CI: add `workflow_dispatch` trigger, re-enable Flutter beta in example CI, and update `actions/setup-java` to v6 ([`4a8ddfc`](https://github.com/JonasWanke/debug_overlay/commit/4a8ddfc9b9932920bdcea575f21c704507d6e5e9), [`e912204`](https://github.com/JonasWanke/debug_overlay/commit/e9122048b2e9bf3b145c6b6f0df2d334b22c490d), [`1bbfe6b`](https://github.com/JonasWanke/debug_overlay/commit/1bbfe6b79da95d9cb004568faa9506599d91ae25))
- re-generate the example app's Android platform directory (Groovy → Kotlin DSL Gradle files) ([`9290fc4`](https://github.com/JonasWanke/debug_overlay/commit/9290fc45fb20099c7fe7c64bcf4878b1d7c1bf82))

## 1.0.0 · 2024-12-22

### ⚠️ BREAKING CHANGES

- convert `DebugHelper` & co. to slivers ([`a23c55c`](https://github.com/JonasWanke/debug_overlay/commit/a23c55c2a81e7e6b9c5d2118b36f05f2a73d3ce9))
  - this avoids stutters for large numbers of logs
  - rename `DebugHelper`'s `child` to `sliver`
- switch from `shake` to `shake_detector` ([`18d59b8`](https://github.com/JonasWanke/debug_overlay/commit/18d59b8e763ed5c9a23f1ff556457d1e9821dc3b))

### 🎉 New Features

- `LogsDebugHelper`: add option to copy all logs ([`2cfbad9`](https://github.com/JonasWanke/debug_overlay/commit/2cfbad9e8abab71fd415196d61ebde22e1e3317d))
- `LogsDebugHelper`: add `logCollection.onlyStoreLogsInDebugMode` to configure whether logs are also stored in non-debug builds ([`8a9d885`](https://github.com/JonasWanke/debug_overlay/commit/8a9d885fe837ee8bc09fab73984f295bc3ad8cf6))

### ⚡ Changes

- increase default log maximum from 50 to 500 ([`1b5a9ae`](https://github.com/JonasWanke/debug_overlay/commit/1b5a9ae8c7118f477a877b05c83f554ca34aa014))

### 📦 Build & CI

- update `device_info_plus` to `>=8.0.0 <12.0.0` ([`9c12480`](https://github.com/JonasWanke/debug_overlay/commit/9c12480189f9d2d8eacb3803922a9fe7a9b6cea6))
- upgrade to Flutter `>=3.27.0-0` ([`5f81679`](https://github.com/JonasWanke/debug_overlay/commit/5f8167953c3e622e8042d570f1fd12a214612351))

## 0.2.12 · 2024-08-29

### 📦 Build & CI

- update `package_info_plus` to `>=3.0.0 <9.0.0` ([#22](https://github.com/JonasWanke/debug_overlay/pull/22)). Thanks to [@nikolashaag](https://github.com/nikolashaag)!
- update `device_info_plus` to `>=8.0.0 <11.0.0` ([`5d91238`](https://github.com/JonasWanke/debug_overlay/commit/5d91238628196187922beeeb8d9429d3e95cb7a7))

## 0.2.11 · 2023-12-04

### 📦 Build & CI

- update `package_info_plus` to `>=3.0.0 <6.0.0` ([`ac133bd`](https://github.com/JonasWanke/debug_overlay/commit/ac133bde2049a8b94f786792c031c1b07f259bf8))

## 0.2.10 · 2023-11-07

### 🎉 New Features

- make `MediaQueryDebugHelper`, `PackageInfoDebugHelper`, and `DeviceInfoDebugHelper` const ([`4a251d2`](https://github.com/JonasWanke/debug_overlay/commit/4a251d20fce941d3347b2a52582b10484f1ad23d))
- add `logsDebugHelper.initialMinLevel` ([`57ae361`](https://github.com/JonasWanke/debug_overlay/commit/57ae3614576e52b74827a76e5ca0c4855084df4b))
- customize level titles in `DiagnosticLevelSelector` ([`3108197`](https://github.com/JonasWanke/debug_overlay/commit/310819732713acf38ad7256cf40eaca8d2307ac8))
- make log entries expandable/collapsible ([`9c480be`](https://github.com/JonasWanke/debug_overlay/commit/9c480be1abac90adec53386172dec85bfb72f829))
- add JSON viewer for log data ([`991bee8`](https://github.com/JonasWanke/debug_overlay/commit/991bee8ded9dfcd1060bd0ce7f47238d63ee8069))
- add missing `key` parameters to widgets ([`b06e5a3`](https://github.com/JonasWanke/debug_overlay/commit/b06e5a3b209b7afc927c06649141c99d4164a83a))
- override `debugFillProperties(…)` ([`6ce47c0`](https://github.com/JonasWanke/debug_overlay/commit/6ce47c084057c0cc54d18afe8000d42ff1635938))

### 📦 Build & CI

- update `device_info_plus` to `>=8.0.0 <10.0.0`, `package_info_plus` to `>=3.0.0 <5.0.0` ([`c2dc258`](https://github.com/JonasWanke/debug_overlay/commit/c2dc258cb01a4d142e3533f9d1a9275e8314fd36)), ([`822ccbc`](https://github.com/JonasWanke/debug_overlay/commit/822ccbc5ed0bf7773923e66fa9054d21c80365b5)) (the newer major releases got retracted)

## 0.2.9 · 2023-10-11

### 📦 Build & CI

- update `device_info_plus` to `>=9.0.0 < 11.0.0`, `package_info_plus` to `>=4.0.0 < 6.0.0` ([`63cca81`](https://github.com/JonasWanke/debug_overlay/commit/63cca816888c3b19cc10e2e010510fdfc9309ae0))

## 0.2.8 · 2023-05-16

### 📦 Build & CI

- upgrade to Flutter `>=3.10.0`, Dart `>=3.0.0 <4.0.0` ([`6dafaa0`](https://github.com/JonasWanke/debug_overlay/commit/6dafaa0afb5d02ccd70ee0b1a198a66678ec70ac))
- update `device_info_plus` to `^9.0.0`, `package_info_plus` to `^4.0.0` ([`be4e68f`](https://github.com/JonasWanke/debug_overlay/commit/be4e68f1a4561e57e72fef8ae5923af340fed162))

## 0.2.7 · 2023-02-17

### 🎉 New Features

- implement `Diagnosticable` for `Log` ([`21a96cb`](https://github.com/JonasWanke/debug_overlay/commit/21a96cbf7d3ffd60da9cfe39dc7e7d6be592339b))

## 0.2.6 · 2023-01-24

### 🎉 New Features

- add `debugOverlay.createShakeDetector`, allowing you to customize the `ShakeDetector` ([`f3cab7c`](https://github.com/JonasWanke/debug_overlay/commit/f3cab7c5a20bb7dea8c9e17260863cc5c1877b80)), closes: [#6](https://github.com/JonasWanke/debug_overlay/issues/6)

## 0.2.5 · 2023-01-24

### 📜 Documentation updates

- fix changelog links ([`b6c3f66`](https://github.com/JonasWanke/debug_overlay/commit/b6c3f66c7dcf678e9c1ef39744601b78c6037e20))

## 0.2.4 · 2023-01-24

### 🎉 New Features

- add option to show newest logs first ([`bdfb520`](https://github.com/JonasWanke/debug_overlay/commit/bdfb52020088c504cf4e6684f32809eb6be51005)), closes: [#5](https://github.com/JonasWanke/debug_overlay/issues/5)

### 📦 Build & CI

- upgrade to Flutter `>=3.3.0`, Dart `>=2.18.0 <3.0.0` ([`5c7230e`](https://github.com/JonasWanke/debug_overlay/commit/5c7230e8c328678ef8679002c62d9c09c8a466ac))
- update `black_hole_flutter` to `^1.0.0` ([`3f40d9f`](https://github.com/JonasWanke/debug_overlay/commit/3f40d9f75a75a5f9c3ee70fceb13d0e48cd643fd))

## 0.2.3 · 2022-11-02

### 📦 Build & CI

- update `device_info_plus` to `^8.0.0`, `package_info_plus` to `^3.0.1` ([`2beb8e5`](https://github.com/JonasWanke/debug_overlay/commit/2beb8e50eddaf73c950d17ebb2292fe77167d662))

## 0.2.2 · 2022-10-10

### 📦 Build & CI

- update `device_info_plus` to `^5.0.5` ([`5c645e6`](https://github.com/JonasWanke/debug_overlay/commit/5c645e63131125ff6740b8546f3f3157d974dbf2))

## 0.2.1 · 2022-08-15

### 🐛 Bug Fixes

- Remove Android ID entry because it [got removed in <kbd>device_info_plus</kbd>](https://pub.dev/packages/device_info_plus/changelog#400) ([`6fc6f21`](https://github.com/JonasWanke/debug_overlay/commit/6fc6f217af77fa4e7d9cbb3d4415529cb8d9801a))

## 0.2.0 · 2022-07-18

### ⚠️ BREAKING CHANGES

- Store logs even if not in debug mode ([`6193833`](https://github.com/JonasWanke/debug_overlay/commit/619383304f15d4771bf2518ff301bca2f925639a))
- Only add default debug helpers in debug mode ([`cc6698e`](https://github.com/JonasWanke/debug_overlay/commit/cc6698e23e290d99a4384fcd8d5eee89a0772e37))

### 📜 Documentation updates

- Add note about DiagnosticsBasedDebugHelper only working in debug mode ([`947a224`](https://github.com/JonasWanke/debug_overlay/commit/947a22477888b79bc0dcd17a572ea3efceaa9fa1))

## 0.1.5 · 2022-07-18

### 🎉 New Features

- add `debugOverlay.enableOnlyInDebugMode` and a corresponding parameter in `DebugOverlay.builder` (both default to `false`) to optionally enable the overlay in release or profile builds ([`f662e57`](https://github.com/JonasWanke/debug_overlay/commit/f662e57289537e002598cbe9872ce6ee3c27b685))

## 0.1.4 · 2022-06-10

### 📦 Build & CI

- update to Flutter 3 ([`15b65ed`](https://github.com/JonasWanke/debug_overlay/commit/15b65edc43ece0850b5c52ba6ef21d5e63086522))

## 0.1.3 · 2022-01-05

### 📦 Build & CI

- remove dependency on the discontinued [<kbd>supercharged</kbd>](https://pub.dev/packages/supercharged) ([`967171d`](https://github.com/JonasWanke/debug_overlay/commit/967171d77d86ec871c380532c94737326430fcc5))

## 0.1.2 · 2021-11-10

### 🏗️ Refactoring

- migrate to `flutter_lints`

### 📦 Build & CI

- update `device_info_plus` to `^3.0.0`
- update `shake` to `^2.0.0`

## 0.1.1 · 2021-03-29

### 🎉 New Features

- support `device_info_plus_platform_interface ^1.0.1`

## 0.1.0 · 2021-03-25

Initial release 🎉
