import 'package:flutter/material.dart';

import '../../flutter/material/tabs.dart';
import '../../flutter/widgets/page_view.dart';
import '../widgets/page_view.dart';

class NestedMTTabBarView extends MTTabBarView {
  /// 是否缓存可滚动页面，不缓存可能导致页面在嵌套滚动时被销毁导致手势事件丢失
  final bool wantKeepAlive;

  const NestedMTTabBarView({
    super.key,
    required super.children,
    super.controller,
    super.physics,
    super.dragStartBehavior,
    super.viewportFraction,
    super.clipBehavior,
    this.wantKeepAlive = true,
  });

  @override
  State<MTTabBarView> createState() => NestedTabBarViewState();
}

class NestedTabBarViewState extends MTTabBarViewState {
  @override
  Widget build(BuildContext context) {
    final notificationListener =
        super.build(context) as NotificationListener<ScrollNotification>;
    final flutterPageView = notificationListener.child as MTPageView;
    return NotificationListener<ScrollNotification>(
      onNotification: notificationListener.onNotification,
      child: NestedMTPageView.custom(
        dragStartBehavior: flutterPageView.dragStartBehavior,
        clipBehavior: flutterPageView.clipBehavior,
        controller: flutterPageView.controller,
        physics: flutterPageView.physics,
        childrenDelegate: flutterPageView.childrenDelegate,
        wantKeepAlive: (widget as NestedMTTabBarView).wantKeepAlive,
      ),
    );
  }
}
