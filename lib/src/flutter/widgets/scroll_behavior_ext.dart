import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

extension ScrollBehaviorExt on ScrollBehavior {
  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.multitouchDragStrategy}
  ///
  /// By default, [MultitouchDragStrategy.latestPointer] is configured to
  /// create drag gestures for non-Apple platforms, and
  /// [MultitouchDragStrategy.averageBoundaryPointers] for Apple platforms.
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return multitouchDragStrategy;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return MultitouchDragStrategy.latestPointer;
    }
  }

  MultitouchDragStrategy get multitouchDragStrategy =>
      MultitouchDragStrategy.latestPointer;
}
