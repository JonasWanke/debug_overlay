import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:black_hole_flutter/black_hole_flutter.dart';

import '../debug_helper.dart';

class MediaOverrideState {
  MediaOverrideState({this.themeMode, this.locale});

  final ThemeMode? themeMode;
  final Locale? locale;

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

class MediaOverrideDebugHelper extends StatefulWidget {
  const MediaOverrideDebugHelper(this.state, {this.supportedLocales});

  final ValueNotifier<MediaOverrideState> state;

  final List<Locale>? supportedLocales;

  @override
  _MediaOverrideDebugHelperState createState() =>
      _MediaOverrideDebugHelperState();
}

class _MediaOverrideDebugHelperState extends State<MediaOverrideDebugHelper> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MediaOverrideState>(
      valueListenable: widget.state,
      builder: (context, currentState, _) => DebugHelper(
        title: Text('Media Overrides'),
        contentPadding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildThemeModeOverride(currentState),
            if (widget.supportedLocales != null)
              _buildLocaleOverride(currentState),
          ],
        ),
      ),
    );
  }

  ThemeMode? themeMode;
  Widget _buildThemeModeOverride(MediaOverrideState currentState) {
    themeMode ??=
        context.theme.brightness.isLight ? ThemeMode.light : ThemeMode.dark;

    return CheckboxListTile(
      title: Text('Theme Mode'),
      controlAffinity: ListTileControlAffinity.leading,
      value: currentState.themeMode != null,
      onChanged: (value) {
        widget.state.value = currentState.copyWith(
          clearThemeMode: !value!,
          themeMode: value ? themeMode! : null,
        );
      },
      secondary: ToggleButtons(
        onPressed: (index) {
          setState(() {
            themeMode = ThemeMode.values[index];
            widget.state.value = currentState.copyWith(themeMode: themeMode!);
          });
        },
        children: [
          for (final themeMode in ThemeMode.values)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(_themeModeToString(themeMode)),
            ),
        ],
        isSelected: [
          for (final themeMode in ThemeMode.values)
            themeMode == (currentState.themeMode ?? this.themeMode!),
        ],
      ),
    );
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Locale? locale;
  Widget _buildLocaleOverride(MediaOverrideState currentState) {
    locale ??= context.locale;

    return CheckboxListTile(
      title: Text('Locale'),
      controlAffinity: ListTileControlAffinity.leading,
      value: currentState.locale != null,
      onChanged: (value) {
        widget.state.value = currentState.copyWith(
          clearLocale: !value!,
          locale: value ? locale! : null,
        );
      },
      secondary: DropdownButton<Locale>(
        value: currentState.locale ?? locale!,
        onChanged: (locale) {
          setState(() {
            this.locale = locale!;
            widget.state.value = currentState.copyWith(locale: locale);
          });
        },
        items: [
          for (final locale in widget.supportedLocales!)
            DropdownMenuItem(
              value: locale,
              child: Text(locale.toLanguageTag()),
            ),
        ],
      ),
    );
  }
}
