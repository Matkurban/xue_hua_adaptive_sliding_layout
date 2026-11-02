import 'package:flutter/widgets.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';

/// 记下本页所在 [ModalRoute]，供路由器询问 PopScope / 走 Navigator 链。
class AdaptivePageHost extends StatefulWidget {
  const AdaptivePageHost({
    super.key,
    required this.router,
    required this.pageKey,
    required this.child,
  });

  final AdaptiveRouter router;
  final LocalKey pageKey;
  final Widget child;

  @override
  State<AdaptivePageHost> createState() => _AdaptivePageHostState();
}

class _AdaptivePageHostState extends State<AdaptivePageHost> {
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) return;
    _unbind();
    _route = route;
    if (route != null) {
      widget.router.registerHostRoute(widget.pageKey, route);
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  void _unbind() {
    if (_route == null) return;
    widget.router.unregisterHostRoute(widget.pageKey, _route!);
    _route = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
