import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:material_ui/material_ui.dart';

import '../debug_tool.dart';

/// The overrides chosen in a [MediaOverrideDebugTool].
///
/// A `null` value means that the app's own setting is used.
class MediaOverrideState({final ThemeMode? themeMode, final Locale? locale}) {
  /// Returns a copy with the given values replaced.
  ///
  /// Pass `clearThemeMode` or `clearLocale` to reset a value to `null`.
  MediaOverrideState copyWith({
    ThemeMode? themeMode,
    bool clearThemeMode = false,
    Locale? locale,
    bool clearLocale = false,
  }) {
    assert(!(clearThemeMode && themeMode != null));
    assert(!(clearLocale && locale != null));

    return MediaOverrideState(
      themeMode: clearThemeMode ? null : themeMode ?? this.themeMode,
      locale: clearLocale ? null : locale ?? this.locale,
    );
  }
}

/// A [DebugTool] to override the theme mode and locale of your app.
///
/// Wrap your app in a widget that listens to [state] and applies the overrides.
class MediaOverrideDebugTool(
  final ValueNotifier<MediaOverrideState> state, {

  /// The locales the user can choose from; they should match your app's.
  ///
  /// The locale override is hidden if this is `null`.
  final List<Locale>? supportedLocales,
}) extends DebugTool {
  this : super(icon: Icons.tune, title: 'Media Overrides');

  @override
  Widget buildSliver(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: state,
      builder: (context, currentState, _) => SliverList.list(
        children: [
          _buildThemeModeOverride(context, currentState),
          if (supportedLocales != null)
            _buildLocaleOverride(context, currentState),
        ],
      ),
    );
  }

  ThemeMode? _themeMode;
  Widget _buildThemeModeOverride(
    BuildContext context,
    MediaOverrideState currentState,
  ) {
    _themeMode ??= context.theme.brightness.isLight ? .light : .dark;

    return CheckboxListTile(
      title: const Text('Theme Mode'),
      controlAffinity: .leading,
      value: currentState.themeMode != null,
      onChanged: (value) {
        state.value = currentState.copyWith(
          clearThemeMode: !value!,
          themeMode: value ? _themeMode! : null,
        );
      },
      secondary: ToggleButtons(
        onPressed: (index) {
          _themeMode = ThemeMode.values[index];
          state.value = currentState.copyWith(themeMode: _themeMode!);
        },
        isSelected: [
          for (final themeMode in ThemeMode.values)
            themeMode == (currentState.themeMode ?? _themeMode!),
        ],
        children: [
          for (final themeMode in ThemeMode.values)
            Padding(
              padding: const .symmetric(horizontal: 4),
              child: Text(_themeModeToString(themeMode)),
            ),
        ],
      ),
    );
  }

  String _themeModeToString(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  Locale? _locale;
  Widget _buildLocaleOverride(
    BuildContext context,
    MediaOverrideState currentState,
  ) {
    _locale ??=
        _closestSupportedLocale(context.locale) ??
        supportedLocales!.firstOrNull;
    final selectedLocale = currentState.locale == null
        ? _locale
        : _closestSupportedLocale(currentState.locale!);

    return CheckboxListTile(
      title: const Text('Locale'),
      controlAffinity: .leading,
      value: currentState.locale != null,
      // Without any supported locale, there is nothing to override.
      onChanged: _locale == null
          ? null
          : (value) {
              state.value = currentState.copyWith(
                clearLocale: !value!,
                locale: value ? _locale! : null,
              );
            },
      secondary: DropdownButton(
        value: selectedLocale,
        onChanged: (locale) {
          _locale = locale!;
          state.value = currentState.copyWith(locale: locale);
        },
        items: [
          for (final locale in supportedLocales!)
            DropdownMenuItem(
              value: locale,
              child: Text(locale.toLanguageTag()),
            ),
        ],
      ),
    );
  }

  /// Returns [locale] if it's supported, otherwise the first supported locale
  /// with the same language, or `null`.
  ///
  /// The dropdown requires its value to be one of its items.
  Locale? _closestSupportedLocale(Locale locale) {
    final supportedLocales = this.supportedLocales!;
    if (supportedLocales.contains(locale)) return locale;

    return supportedLocales
        .where((it) => it.languageCode == locale.languageCode)
        .firstOrNull;
  }
}
