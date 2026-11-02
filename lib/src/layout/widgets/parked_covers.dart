import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_route_match.dart';
import 'package:xue_hua_adaptive_sliding_layout/src/router/adaptive_router.dart';

/// cover Navigator 的透明底页：[Navigator.pages] 不能为空，所以每个分支的
/// cover Navigator 常驻这一页，页面清空时它什么也不画（外层 IgnorePointer）。
class CoverBasePage extends Page<void> {
  const CoverBasePage()
    : super(key: const ValueKey<String>('adaptive-cover-base'));

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

/// 非当前分支的 cover 页停放处：离屏、无焦点、无语义、不响应点击，也不向上
/// 发 NavigationNotification（返回键只看 chrome Navigator）。
class ParkedCovers extends StatelessWidget {
  const ParkedCovers({super.key, required this.router, required this.pages});

  final AdaptiveRouter router;
  final List<AdaptiveRouteMatch> pages;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: NotificationListener<NavigationNotification>(
              onNotification: (_) => true,
              child: Navigator(
                pages: [
                  const CoverBasePage(),
                  for (final match in pages)
                    router.pageFor(context, match, keepState: true),
                ],
                onDidRemovePage: router.handleRemovedPage,
                transitionDelegate: router.relocationDelegate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
