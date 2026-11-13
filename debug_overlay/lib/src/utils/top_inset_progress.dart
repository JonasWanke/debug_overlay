import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// How much of the top view padding the overlay's header reserves.
///
/// This is an [InheritedWidget] instead of a modified [MediaQuery], so that
/// tools still see the app's real [MediaQuery].
class const TopInsetProgress({
  super.key,

  /// `0` if the sheet is small and doesn't reach the top of the screen, `1` if
  /// it covers the top view padding.
  required final double progress,
  required super.child,
}) extends InheritedWidget {
  /// Returns the closest [progress] or `1` if there is none.
  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<TopInsetProgress>()
            ?.progress ??
        1;
  }

  @override
  bool updateShouldNotify(TopInsetProgress oldWidget) =>
      progress != oldWidget.progress;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('progress', progress));
  }
}
