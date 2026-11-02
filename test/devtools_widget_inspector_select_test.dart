import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// 复刻 Flutter `WidgetInspector._hitTest` 的精确命中与面积排序逻辑：
/// 遍历 `debugDescribeChildren()`，仅跳过 `DiagnosticsTreeStyle.offstage`
/// 或超出 `describeApproximatePaintClip` 的子树，并按 `semanticBounds` 面积升序排列。
List<RenderObject> _inspectorHitTest(Offset position, RenderObject root) {
  final regularHits = <RenderObject>[];
  final edgeHits = <RenderObject>[];

  bool hitTestHelper(RenderObject object, Matrix4 transform) {
    var hit = false;
    final inverse = Matrix4.tryInvert(transform);
    if (inverse == null) return false;
    final localPosition = MatrixUtils.transformPoint(inverse, position);

    final children = object.debugDescribeChildren();
    for (var i = children.length - 1; i >= 0; i -= 1) {
      final diagnostics = children[i];
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject) {
        continue;
      }
      final child = diagnostics.value! as RenderObject;
      final paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition)) {
        continue;
      }
      final childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (hitTestHelper(child, childTransform)) {
        hit = true;
      }
    }

    final bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      if (!bounds.deflate(5.0).contains(localPosition)) {
        edgeHits.add(object);
      }
    }
    if (hit) {
      regularHits.add(object);
    }
    return hit;
  }

  hitTestHelper(root, root.getTransformTo(null));
  double area(RenderObject object) {
    final size = object.semanticBounds.size;
    return size.width * size.height;
  }

  regularHits.sort((a, b) => area(a).compareTo(area(b)));
  return <RenderObject>{...edgeHits, ...regularHits}.toList();
}

AdaptiveRouter _buildRouter({bool hidesBottomBar = true}) {
  return AdaptiveRouter(
    initialLocation: '/home',
    routes: [
      AdaptiveRoute(
        path: '/fullscreen',
        fullscreen: true,
        builder: (context, state) => Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('fullscreen-target'),
              width: 240,
              height: 120,
              child: const ColoredBox(color: Colors.purple),
            ),
          ),
        ),
      ),
      AdaptiveShellRoute(
        builder: (context, shell, child) => Scaffold(
          body: child,
          bottomNavigationBar: shell.isCompact
              ? const SizedBox(height: 56, child: Text('bottom-bar'))
              : null,
        ),
        branches: [
          AdaptiveBranch(
            routes: [
              AdaptiveRoute(
                path: '/home',
                builder: (context, state) => Scaffold(
                  body: Center(
                    // 故意在根页面相同中心区域放置面积更小的组件（40x40），
                    // 验证进入深层页面后 WidgetInspector 不会因为面积排序选中根页面组件。
                    child: SizedBox(
                      key: const Key('root-tiny-target'),
                      width: 40,
                      height: 40,
                      child: const ColoredBox(color: Colors.red),
                    ),
                  ),
                ),
                routes: [
                  AdaptiveRoute(
                    path: 'level1',
                    hidesBottomBarWhenPushed: hidesBottomBar,
                    builder: (context, state) => Scaffold(
                      body: Center(
                        child: SizedBox(
                          key: const Key('level1-small-target'),
                          width: 80,
                          height: 80,
                          child: const ColoredBox(color: Colors.blue),
                        ),
                      ),
                    ),
                    routes: [
                      AdaptiveRoute(
                        path: 'level2',
                        hidesBottomBarWhenPushed: hidesBottomBar,
                        builder: (context, state) => Scaffold(
                          body: Center(
                            child: SizedBox(
                              key: const Key('level2-large-target'),
                              width: 200,
                              height: 200,
                              child: const ColoredBox(color: Colors.green),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final hidesBottomBar in [true, false]) {
    for (final width in [400.0, 700.0]) {
      testWidgets('DevTools WidgetInspector hits only top page at width $width '
          '(hidesBottomBar: $hidesBottomBar)', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = _buildRouter(hidesBottomBar: hidesBottomBar);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        final rootRenderObject = tester.renderObject(
          find.byKey(const Key('root-tiny-target'), skipOffstage: false),
        );

        // 进入第 2 层页面 (/home/level1)
        router.pushNamed('/home/level1');
        await tester.pumpAndSettle();

        final level1RenderObject = tester.renderObject(
          find.byKey(const Key('level1-small-target'), skipOffstage: false),
        );
        final center = tester.getCenter(
          find.byKey(const Key('level1-small-target')),
        );
        var hits = _inspectorHitTest(center, tester.binding.renderViews.first);
        expect(hits, contains(level1RenderObject));
        expect(
          hits,
          isNot(contains(rootRenderObject)),
          reason: 'Root page render object must be offstage in DevTools',
        );

        // 进入第 3 层页面 (/home/level1/level2)
        router.pushNamed('/home/level1/level2');
        await tester.pumpAndSettle();

        final level2RenderObject = tester.renderObject(
          find.byKey(const Key('level2-large-target'), skipOffstage: false),
        );
        final center2 = tester.getCenter(
          find.byKey(const Key('level2-large-target')),
        );
        hits = _inspectorHitTest(center2, tester.binding.renderViews.first);
        expect(hits, contains(level2RenderObject));
        expect(
          hits,
          isNot(contains(rootRenderObject)),
          reason: 'Root page must not be hit at depth 3',
        );
        expect(
          hits,
          isNot(contains(level1RenderObject)),
          reason: 'Level 1 page must not be hit at depth 3',
        );

        // 压入根 Navigator 全屏页 (/fullscreen)
        router.pushNamed('/fullscreen');
        await tester.pumpAndSettle();

        final fullscreenRenderObject = tester.renderObject(
          find.byKey(const Key('fullscreen-target'), skipOffstage: false),
        );
        final centerFs = tester.getCenter(
          find.byKey(const Key('fullscreen-target')),
        );
        hits = _inspectorHitTest(centerFs, tester.binding.renderViews.first);
        expect(hits, contains(fullscreenRenderObject));
        expect(hits, isNot(contains(rootRenderObject)));
        expect(hits, isNot(contains(level1RenderObject)));
        expect(hits, isNot(contains(level2RenderObject)));

        // 逐层 pop 回退后恢复可命中
        router.pop();
        await tester.pumpAndSettle();
        hits = _inspectorHitTest(center2, tester.binding.renderViews.first);
        expect(hits, contains(level2RenderObject));
        expect(hits, isNot(contains(rootRenderObject)));

        router.pop();
        await tester.pumpAndSettle();
        hits = _inspectorHitTest(center, tester.binding.renderViews.first);
        expect(hits, contains(level1RenderObject));
        expect(hits, isNot(contains(rootRenderObject)));

        router.pop();
        await tester.pumpAndSettle();
        hits = _inspectorHitTest(center, tester.binding.renderViews.first);
        expect(hits, contains(rootRenderObject));
      });
    }
  }

  testWidgets(
    'expanded two-column mode marks offscreen panes (i < start) as offstage',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.pushNamed('/home/level1');
      await tester.pumpAndSettle();
      router.pushNamed('/home/level1/level2');
      await tester.pumpAndSettle();

      // 深度为 3 时，/home 滑出左侧视口，应处于 offstage 状态
      expect(find.byKey(const Key('root-tiny-target')), findsNothing);
      expect(
        find.byKey(const Key('root-tiny-target'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(const Key('level1-small-target')), findsOneWidget);
      expect(find.byKey(const Key('level2-large-target')), findsOneWidget);
    },
  );
}
