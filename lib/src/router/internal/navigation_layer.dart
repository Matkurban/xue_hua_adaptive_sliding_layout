import 'package:flutter/widgets.dart';

/// `AdaptiveRouter.popFrom` / `AdaptiveRouter.maybePopFrom` 对 context 的落点。
sealed class NavigationLayer {
  const NavigationLayer();
}

/// 要关的弹层所在 Navigator。
final class PopupNavigationLayer extends NavigationLayer {
  const PopupNavigationLayer(this.navigator);

  final NavigatorState navigator;
}

/// context 在栈顶页里且没被盖住：走页面路径。
final class TopPageNavigationLayer extends NavigationLayer {
  const TopPageNavigationLayer();
}

/// context 在非栈顶页里且没被盖住：无事可做。
final class IdleNavigationLayer extends NavigationLayer {
  const IdleNavigationLayer();
}

/// context 不在托管页面 / 弹层里（壳层 chrome、壳外）：回落到全局动词。
final class GlobalNavigationLayer extends NavigationLayer {
  const GlobalNavigationLayer();
}
