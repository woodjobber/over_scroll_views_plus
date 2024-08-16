// ignore_for_file: doc_directive_missing_closing_tag

import 'package:flutter/material.dart';
import 'package:over_scroll_views_plus/src/component/widgets/scrollable.dart';

import '../../flutter/widgets/page_view.dart';
import '../../flutter/widgets/scrollable.dart';
import '../../nested_scroll_notification.dart';
import '../../wrapper_keep_alive.dart';

/// A scrollable list that works page by page.
///
/// Each child of a page view is forced to be the same size as the viewport.
///
/// You can use a [PageController] to control which page is visible in the view.
/// In addition to being able to control the pixel offset of the content inside
/// the [MTPageView], a [PageController] also lets you control the offset in terms
/// of pages, which are increments of the viewport size.
///
/// The [PageController] can also be used to control the
/// [PageController.initialPage], which determines which page is shown when the
/// [MTPageView] is first constructed, and the [PageController.viewportFraction],
/// which determines the size of the pages as a fraction of the viewport size.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=J1gE9xvph-A}
///
/// {@tool dartpad}
/// Here is an example of [MTPageView]. It creates a centered [Text] in each of the three pages
/// which scroll horizontally.
///
/// ** See code in examples/api/lib/widgets/page_view/page_view.0.dart **
/// {@end-tool}
///
/// ## Persisting the scroll position during a session
///
/// Scroll views attempt to persist their scroll position using [PageStorage].
/// For a [MTPageView], this can be disabled by setting [PageController.keepPage]
/// to false on the [controller]. If it is enabled, using a [PageStorageKey] for
/// the [key] of this widget is recommended to help disambiguate different
/// scroll views from each other.
///
/// See also:
///
///  * [PageController], which controls which page is visible in the view.
///  * [SingleChildScrollView], when you need to make a single child scrollable.
///  * [ListView], for a scrollable list of boxes.
///  * [GridView], for a scrollable grid of boxes.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
class NestedMTPageView extends MTPageView {
  /// 是否缓存可滚动页面，不缓存可能导致页面在嵌套滚动时被销毁导致手势事件丢失
  final bool wantKeepAlive;

  /// Creates a scrollable list that works page by page from an explicit [List]
  /// of widgets.
  ///
  /// This constructor is appropriate for page views with a small number of
  /// children because constructing the [List] requires doing work for every
  /// child that could possibly be displayed in the page view, instead of just
  /// those children that are actually visible.
  ///
  /// Like other widgets in the framework, this widget expects that
  /// the [children] list will not be mutated after it has been passed in here.
  /// See the documentation at [SliverChildListDelegate.children] for more details.
  ///
  NestedMTPageView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.physics,
    super.pageSnapping,
    super.onPageChanged,
    super.children,
    super.dragStartBehavior,
    super.allowImplicitScrolling,
    super.restorationId,
    super.clipBehavior,
    super.scrollBehavior,
    super.padEnds,
    this.wantKeepAlive = true,
  });

  /// Creates a scrollable list that works page by page using widgets that are
  /// created on demand.
  ///
  /// This constructor is appropriate for page views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null [itemCount] lets the [MTPageView] compute the maximum
  /// scroll extent.
  ///
  /// [itemBuilder] will be called only with indices greater than or equal to
  /// zero and less than [itemCount].
  ///
  /// {@macro flutter.widgets.ListView.builder.itemBuilder}
  ///
  /// The [findChildIndexCallback] corresponds to the
  /// [SliverChildBuilderDelegate.findChildIndexCallback] property. If null,
  /// a child widget may not map to its existing [RenderObject] when the order
  /// of children returned from the children builder changes.
  /// This may result in state-loss. This callback needs to be implemented if
  /// the order of the children may change at a later time.
  NestedMTPageView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.physics,
    super.pageSnapping,
    super.onPageChanged,
    required super.itemBuilder,
    super.findChildIndexCallback,
    super.itemCount,
    super.dragStartBehavior,
    super.allowImplicitScrolling,
    super.restorationId,
    super.clipBehavior,
    super.scrollBehavior,
    super.padEnds,
    this.wantKeepAlive = true,
  }) : super.builder();

  /// Creates a scrollable list that works page by page with a custom child
  /// model.
  ///
  /// This example shows a [MTPageView] that uses a custom [SliverChildBuilderDelegate] to support child
  /// reordering.
  const NestedMTPageView.custom({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.physics,
    super.pageSnapping,
    super.onPageChanged,
    required super.childrenDelegate,
    super.dragStartBehavior,
    super.allowImplicitScrolling,
    super.restorationId,
    super.clipBehavior,
    super.scrollBehavior,
    super.padEnds,
    this.wantKeepAlive = true,
  }) : super.custom();

  @override
  State<MTPageView> createState() => _NestedPageViewState();
}

class _NestedPageViewState extends MTPageViewState {
  bool? _ignoreOverscroll;
  ScrollDragController? _dragController;

  /// 处理滚动事件通知
  bool _handleNotification(
    BuildContext context,
    ScrollNotification notification,
  ) {
    // 不处理默认滚动事件
    if (notification.depth == 0) {
      return false;
    }

    // 获取可滚动组件当前位置信息
    final position = controller.position;

    // 当前不允许滚动
    if (!position.physics.shouldAcceptUserOffset(position)) {
      return false;
    }

    // 如果当前组件与边界滚动事件的滚动方向不一致
    if (position.axis != notification.metrics.axis) {
      return false;
    }

    // 处理边界滚动事件
    if (notification is OverscrollNotification) {
      // 如果被父组件通知需要忽略边界滚动事件
      if (_ignoreOverscroll == true) {
        return false;
      }
      // 拖动被取消的回调，不需要调用 dispose 方法，不然会死循环
      void dragCancelCallback() => _dragController = null;
      // 滚动位置超出可滚动范围，自定义拖动事件控制器并保存，不要使用 ScrollStartNotification 携带的 DragStartDetails 数据作为参数
      // 如从可滚动 TabBar 的第三项开始滚动到第一项并结束滚动，依次接收到的滚动事件的序列可能如下： Start, End, Start, End
      _dragController ??= position.drag(DragStartDetails(), dragCancelCallback)
          as ScrollDragController;
      // 如果存在滚动数据
      if (notification.dragDetails != null) {
        // 开始处理拖动事件
        _dragController?.update(notification.dragDetails!);
      }
      // 判断当前组件位置是否已到达边界
      if (position.hasPixels && position.atEdge) {
        // 处理多层嵌套，到达边界后发送通知，如果还有父组件则将后续边界滚动事件全部移交给父组件
        NestedScrollNotification(
          metrics: notification.metrics,
          context: notification.context,
          expectType: runtimeType,
          callback: () => _ignoreOverscroll = true,
        ).dispatch(context);
      }
      // 消耗滚动事件
      return true;
    }

    // 处理滚动结束事件
    if (notification is ScrollEndNotification) {
      if (notification.dragDetails != null) {
        // 滚动结束时还有额外的滚动数据，需要继续处理，如：子组件快速滑动切换到父组件
        _dragController?.end(notification.dragDetails!);
      } else {
        // 滚动结束时没有额外的滚动数据，直接复位页面位置
        _dragController?.cancel();
      }
      // 清理页面拖动数据
      _dragController?.dispose();
      _dragController = _ignoreOverscroll = null;
      return false;
    }

    // 处理嵌套滚动事件
    if (notification is NestedScrollNotification) {
      if (runtimeType == notification.expectType) {
        // 通知子组件忽略边界滚动事件
        notification.callback();
        // 消耗嵌套通知事件
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _dragController?.dispose();
    _dragController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationListener =
        super.build(context) as NotificationListener<ScrollNotification>;
    final scrollable = notificationListener.child as MTScrollable;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        return notificationListener.onNotification!(notification) ||
            _handleNotification(context, notification);
      },
      child: WrapperKeepAlive(
        wantKeepAlive: (widget as NestedMTPageView).wantKeepAlive,
        child: OverscrollMTScrollable.from(scrollable),
      ),
    );
  }
}
