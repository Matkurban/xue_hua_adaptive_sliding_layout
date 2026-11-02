import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/pane_scope.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/layout/widgets/sliding_dismissal_binder.dart';

/// 栏内独立 [Navigator]，让栏内 Overlay 不冒到隔壁栏。
class PaneNavigator extends StatelessWidget {
  const PaneNavigator({super.key, required this.pane, required this.onPop});

  final SlidingPane pane;
  final VoidCallback? onPop;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (routeContext) {
            return SlidingDismissalBinder(onPop: onPop, child: pane.child);
          },
        );
      },
    );
  }
}
