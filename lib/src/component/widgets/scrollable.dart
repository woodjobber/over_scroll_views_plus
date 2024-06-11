// ignore_for_file: unused_import
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:over_scroll_views_plus/src/flutter/widgets/scroll_behavior_ext.dart';

import '../../flutter/widgets/scrollable.dart';
import '../../flutter/widgets/scrollable_helpers.dart';
import '../../nested_scroll_notification.dart';
import '../../overscroll_gestures.dart';

class OverscrollMTScrollable extends MTScrollable {
  const OverscrollMTScrollable({
    super.key,
    super.axisDirection,
    super.controller,
    super.physics,
    required super.viewportBuilder,
    super.incrementCalculator,
    super.excludeFromSemantics,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.restorationId,
    super.scrollBehavior,
    super.clipBehavior,
  });

  static MTScrollIncrementCalculator? _getScrollIncrementCalculator(
    MTScrollable scrollable,
  ) {
    final incrementCalculator = scrollable.incrementCalculator;
    if (incrementCalculator == null) {
      return null;
    }
    return (details) {
      return incrementCalculator(
        MTScrollIncrementDetails(
          metrics: details.metrics,
          type: MTScrollIncrementType.values[details.type.index],
        ),
      );
    };
  }

  /// 将 Scrollable 转换为 OverscrollScrollable
  OverscrollMTScrollable.from(MTScrollable scrollable)
      : super(
          key: scrollable.key,
          axisDirection: scrollable.axisDirection,
          controller: scrollable.controller,
          physics: scrollable.physics,
          viewportBuilder: scrollable.viewportBuilder,
          incrementCalculator: _getScrollIncrementCalculator(scrollable),
          excludeFromSemantics: scrollable.excludeFromSemantics,
          semanticChildCount: scrollable.semanticChildCount,
          dragStartBehavior: scrollable.dragStartBehavior,
          restorationId: scrollable.restorationId,
          scrollBehavior: scrollable.scrollBehavior,
          clipBehavior: scrollable.clipBehavior,
        );

  @override
  MTScrollableState createState() => _OverscrollScrollableState();
}

class _OverscrollScrollableState extends MTScrollableState {
  /// 是否已经滚动到边界
  bool _overscroll = false;

  /// 代理手势更新事件
  GestureDragUpdateCallback? _proxyOnUpdate(GestureDragUpdateCallback? parent) {
    // 如果已经滚动到了边界则不再响应移动事件
    return _overscroll ? null : parent;
  }

  /// 处理手势移动事件
  _onMoveEvent(PointerMoveEvent event, Offset delta, double primaryDelta) {
    // 如果已经滚动到边界并且又继续移动
    if (_overscroll && primaryDelta != 0.0) {
      // 边界滚动事件通知
      OverscrollNotification(
        metrics: position.copyWith(),
        context: context,
        overscroll: primaryDelta,
        dragDetails: DragUpdateDetails(
          sourceTimeStamp: event.timeStamp,
          delta: delta,
          primaryDelta: primaryDelta,
          globalPosition: event.position,
          localPosition: event.localPosition,
        ),
      ).dispatch(context);
    }
  }

  @override
  set gestureRecognizers(value) {
    super.gestureRecognizers = value.map((key, value) {
      if (key == VerticalDragGestureRecognizer) {
        return MapEntry(
          OverscrollVerticalDragGestureRecognizer,
          GestureRecognizerFactoryWithHandlers<
              OverscrollVerticalDragGestureRecognizer>(
            () => OverscrollVerticalDragGestureRecognizer(
              proxyOnUpdate: _proxyOnUpdate,
              onPointerMoveEvent: _onMoveEvent,
            ),
            (instance) => value.initializer(instance
              ..dragStartBehavior = widget.dragStartBehavior
              ..multitouchDragStrategy =
                  configuration.getMultitouchDragStrategy(context)
              ..supportedDevices = configuration.dragDevices),
          ),
        );
      } else if (key == HorizontalDragGestureRecognizer) {
        return MapEntry(
          OverscrollHorizontalDragGestureRecognizer,
          GestureRecognizerFactoryWithHandlers<
              OverscrollHorizontalDragGestureRecognizer>(
            () => OverscrollHorizontalDragGestureRecognizer(
              proxyOnUpdate: _proxyOnUpdate,
              onPointerMoveEvent: _onMoveEvent,
            ),
            (instance) => value.initializer(instance
              ..dragStartBehavior = widget.dragStartBehavior
              ..multitouchDragStrategy =
                  configuration.getMultitouchDragStrategy(context)
              ..supportedDevices = configuration.dragDevices),
          ),
        );
      }
      return MapEntry(key, value);
    });
  }

  /// 处理滚动事件
  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      // 设置边界滚动状态
      _overscroll = true;
    } else if (notification is ScrollEndNotification) {
      // 重置边界滚动状态
      _overscroll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // 如果当前组件与边界滚动事件的滚动方向不一致
        if (axisDirectionToAxis(axisDirection) != notification.metrics.axis) {
          return false;
        }
        if (notification.depth == 0) {
          // 当边界滚动事件的深度只有一层时，等查询有指定类型的父组件后再进一步处理滚动事件，避免当前组件作为最外层组件时无法正常滚动
          NestedScrollNotification(
            metrics: notification.metrics,
            context: notification.context,
            expectType: runtimeType,
            callback: () => _handleScrollNotification(notification),
          ).dispatch(context);
        } else if (notification is NestedScrollNotification) {
          if (runtimeType == notification.expectType) {
            // 通知子组件停用滚动事件
            notification.callback();
            // 消耗嵌套通知事件
            return true;
          }
        } else {
          _handleScrollNotification(notification);
        }
        return false;
      },
      child: super.build(context),
    );
  }
}
