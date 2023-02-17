# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- Template:
## NEW · 2023-xx-xx

### ⚠️ BREAKING CHANGES
### 🎉 New Features
### ⚡ Changes
### 🐛 Bug Fixes
### 📜 Documentation updates
### 🏗️ Refactoring
### 📦 Build & CI
-->

## 0.2.7 · 2023-02-17

### 🎉 New Features
* implement `Diagnosticable` for `Log` ([`21a96cb`](https://github.com/JonasWanke/debug_overlay/commit/21a96cbf7d3ffd60da9cfe39dc7e7d6be592339b))

## 0.2.6 · 2023-01-24

### 🎉 New Features
* add `debugOverlay.createShakeDetector`, allowing you to customize the `ShakeDetector` ([`f3cab7c`](https://github.com/JonasWanke/debug_overlay/commit/f3cab7c5a20bb7dea8c9e17260863cc5c1877b80)), closes: [#6](https://github.com/JonasWanke/debug_overlay/issues/6)

## 0.2.5 · 2023-01-24

### 📜 Documentation updates
* fix changelog links ([`b6c3f66`](https://github.com/JonasWanke/debug_overlay/commit/b6c3f66c7dcf678e9c1ef39744601b78c6037e20))

## 0.2.4 · 2023-01-24

### 🎉 New Features
* add option to show newest logs first ([`bdfb520`](https://github.com/JonasWanke/debug_overlay/commit/bdfb52020088c504cf4e6684f32809eb6be51005)), closes: [#5](https://github.com/JonasWanke/debug_overlay/issues/5)

### 📦 Build & CI
* upgrade to Flutter: `>=3.3.0`, Dart `>=2.18.0 <3.0.0` ([`5c7230e`](https://github.com/JonasWanke/debug_overlay/commit/5c7230e8c328678ef8679002c62d9c09c8a466ac))
* update `black_hole_flutter` to `^1.0.0` ([`3f40d9f`](https://github.com/JonasWanke/debug_overlay/commit/3f40d9f75a75a5f9c3ee70fceb13d0e48cd643fd))

## 0.2.3 · 2022-11-02

### 📦 Build & CI
* Update `device_info_plus` to `^8.0.0`, `package_info_plus` to `^3.0.1` ([`2beb8e5`](https://github.com/JonasWanke/debug_overlay/commit/2beb8e50eddaf73c950d17ebb2292fe77167d662))

## 0.2.2 · 2022-10-10

### 📦 Build & CI
* Update `device_info_plus` to `^5.0.5` ([`5c645e6`](https://github.com/JonasWanke/debug_overlay/commit/5c645e63131125ff6740b8546f3f3157d974dbf2))

## 0.2.1 · 2022-08-15

### 🐛 Bug Fixes
* Remove Android ID entry because it [got removed in <kbd>device_info_plus</kbd>](https://pub.dev/packages/device_info_plus/changelog#400) ([`6fc6f21`](https://github.com/JonasWanke/debug_overlay/commit/6fc6f217af77fa4e7d9cbb3d4415529cb8d9801a))

## 0.2.0 · 2022-07-18

### ⚠️ BREAKING CHANGES
* Store logs even if not in debug mode ([`6193833`](https://github.com/JonasWanke/debug_overlay/commit/619383304f15d4771bf2518ff301bca2f925639a))
* Only add default debug helpers in debug mode ([`cc6698e`](https://github.com/JonasWanke/debug_overlay/commit/cc6698e23e290d99a4384fcd8d5eee89a0772e37))

### 📜 Documentation updates
* Add note about DiagnosticsBasedDebugHelper only working in debug mode ([`947a224`](https://github.com/JonasWanke/debug_overlay/commit/947a22477888b79bc0dcd17a572ea3efceaa9fa1))

## 0.1.5 · 2022-07-18

### 🎉 New Features
* add `debugOverlay.enableOnlyInDebugMode` and a corresponding parameter in `DebugOverlay.builder` (both default to `false`) to optionally enable the overlay in release or profile builds ([`f662e57`](https://github.com/JonasWanke/debug_overlay/commit/f662e57289537e002598cbe9872ce6ee3c27b685))

## 0.1.4 · 2022-06-10

### 📦 Build & CI
* update to Flutter 3 ([`15b65ed`](https://github.com/JonasWanke/debug_overlay/commit/15b65edc43ece0850b5c52ba6ef21d5e63086522))

## 0.1.3 · 2022-01-05

### 📦 Build & CI
* remove dependency on the discontinued [<kbd>supercharged</kbd>](https://pub.dev/packages/supercharged) ([`967171d`](https://github.com/JonasWanke/debug_overlay/commit/967171d77d86ec871c380532c94737326430fcc5))

## 0.1.2 · 2021-11-10

### 🏗️ Refactoring
* migrate to `flutter_lints`

### 📦 Build & CI
* update `device_info_plus` to `^3.0.0`
* update `shake` to `^2.0.0`

## 0.1.1 · 2021-03-29

### 🎉 New Features
* support `device_info_plus_platform_interface ^1.0.1`

## 0.1.0 · 2021-03-25

Initial release 🎉
