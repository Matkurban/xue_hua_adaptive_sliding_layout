import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';

/// 仅栈顶栏向内部 [ModalRoute] 注册 [LocalHistoryEntry]，默认 AppBar 才有返回。
///
/// 滑动栈 pop 走本 entry 的 onRemove → [onPop]（通常是 `AdaptiveRouter.maybePop`）。
class SlidingDismissalBinder extends StatefulWidget {
  const SlidingDismissalBinder({
    super.key,
    required this.child,
    required this.onPop,
  });

  final Widget child;
  final VoidCallback? onPop;

  @override
  State<SlidingDismissalBinder> createState() => _SlidingDismissalBinderState();
}

class _SlidingDismissalBinderState extends State<SlidingDismissalBinder> {
  LocalHistoryEntry? _entry;
  ModalRoute<dynamic>? _route;
  bool _popOnRemove = true;
  bool _dependenciesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showBack = AdaptivePaneScope.maybeOf(context)?.showBack ?? false;
    if (!showBack) {
      _detachWithoutPop();
    } else if (!_dependenciesInitialized) {
      _attach();
    } else if (_entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _entry != null) return;
        final scope = context
            .getInheritedWidgetOfExactType<AdaptivePaneScope>();
        if (scope != null && scope.showBack) _attach();
      });
    }
    _dependenciesInitialized = true;
  }

  @override
  void dispose() {
    _detachWithoutPop();
    super.dispose();
  }

  void _attach() {
    if (_entry != null) return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    _route = route;
    _popOnRemove = true;
    _entry = LocalHistoryEntry(onRemove: _onRemove);
    route.addLocalHistoryEntry(_entry!);
  }

  void _onRemove() {
    _entry = null;
    _route = null;
    if (!_popOnRemove) return;
    final onPop = widget.onPop;
    if (onPop == null) return;
    onPop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _entry != null) return;
      final scope = context.getInheritedWidgetOfExactType<AdaptivePaneScope>();
      if (scope != null && scope.showBack) _attach();
    });
  }

  void _detachWithoutPop() {
    final entry = _entry;
    final route = _route;
    if (entry == null || route == null) {
      _entry = null;
      _route = null;
      _popOnRemove = true;
      return;
    }
    _popOnRemove = false;
    route.removeLocalHistoryEntry(entry);
    _entry = null;
    _route = null;
    _popOnRemove = true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
