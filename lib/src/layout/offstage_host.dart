import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 保持子树布局尺寸与 [TickerMode] 不变，但在处于离屏或被上层不透明路由完全遮挡时：
/// - `debugDescribeChildren` 将子节点标记为 [DiagnosticsTreeStyle.offstage]，并令
///   `describeApproximatePaintClip` 与 `semanticBounds` 返回 [Rect.zero]，使 Flutter
///   DevTools `WidgetInspector` 点击选择组件时直接跳过被遮挡的下层页面或已滑出视口的栏位；
/// - `Element.debugVisitOnstageChildren` 跳过子节点，使 `skipOffstage: true` 的查找
///   与标准 [Navigator] 一致地忽略被遮挡页面；
/// - 短路 `paint`、`hitTest` 与 `visitChildrenForSemantics`，避免后台被遮挡页无意义重绘。
class OffstagePageHost extends SingleChildRenderObjectWidget {
  const OffstagePageHost({
    super.key,
    this.offstage = false,
    this.offstageListenable,
    required super.child,
  });

  /// 静态离屏标记。与 [offstageListenable] 任一为 true 即视为离屏。
  final bool offstage;

  /// 动态离屏通知器（由上层路由转场完成状态或滑动视口动画状态驱动）。
  /// 直接在 RenderObject 与 Element 层读取和监听，不触发子树 Widget 重建或
  /// `didChangeDependencies`。
  final ValueListenable<bool>? offstageListenable;

  bool get isEffectiveOffstage =>
      offstage || (offstageListenable?.value ?? false);

  @override
  SingleChildRenderObjectElement createElement() => _OffstagePageElement(this);

  @override
  RenderOffstagePage createRenderObject(BuildContext context) {
    return RenderOffstagePage(offstage, offstageListenable);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderOffstagePage renderObject,
  ) {
    renderObject
      ..offstage = offstage
      ..offstageListenable = offstageListenable;
  }
}

class _OffstagePageElement extends SingleChildRenderObjectElement {
  _OffstagePageElement(OffstagePageHost super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if ((widget as OffstagePageHost).isEffectiveOffstage) return;
    super.debugVisitOnstageChildren(visitor);
  }
}

class RenderOffstagePage extends RenderProxyBox {
  RenderOffstagePage(this._offstage, [this._offstageListenable]);

  bool _offstage;
  ValueListenable<bool>? _offstageListenable;

  bool get isEffectiveOffstage =>
      _offstage || (_offstageListenable?.value ?? false);

  set offstage(bool value) {
    if (_offstage == value) return;
    _offstage = value;
    _onOffstageChanged();
  }

  set offstageListenable(ValueListenable<bool>? value) {
    if (identical(_offstageListenable, value)) return;
    if (attached) {
      _offstageListenable?.removeListener(_onOffstageChanged);
      value?.addListener(_onOffstageChanged);
    }
    _offstageListenable = value;
    _onOffstageChanged();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offstageListenable?.addListener(_onOffstageChanged);
  }

  @override
  void detach() {
    _offstageListenable?.removeListener(_onOffstageChanged);
    super.detach();
  }

  void _onOffstageChanged() {
    markNeedsSemanticsUpdate();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (isEffectiveOffstage) return false;
    return super.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (isEffectiveOffstage) return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    return isEffectiveOffstage ? Rect.zero : null;
  }

  @override
  Rect get semanticBounds =>
      isEffectiveOffstage ? Rect.zero : super.semanticBounds;

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final RenderBox? currentChild = child;
    if (currentChild == null) return const <DiagnosticsNode>[];
    return <DiagnosticsNode>[
      currentChild.toDiagnosticsNode(
        name: 'child',
        style: isEffectiveOffstage
            ? DiagnosticsTreeStyle.offstage
            : DiagnosticsTreeStyle.sparse,
      ),
    ];
  }
}
