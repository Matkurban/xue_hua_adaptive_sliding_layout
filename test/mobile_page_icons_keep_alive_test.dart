import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

/// Simulates an [ImageProvider] (like [AssetImage] backed by [CachingAssetBundle])
/// whose [obtainKey] completes in a microtask (`Future.value`, not `SynchronousFuture`).
class _AsyncKeyIconProvider extends ImageProvider<String> {
  const _AsyncKeyIconProvider(this.id);

  final String id;

  // 1x1 transparent PNG
  static final Uint8List _pngBytes = Uint8List.fromList(const <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  Future<String> obtainKey(ImageConfiguration configuration) {
    // Intentionally return a microtask Future (not SynchronousFuture) to match
    // AssetManifest.loadFromAssetBundle after CachingAssetBundle caches the Future.
    return Future<String>.value(id);
  }

  @override
  ImageStreamCompleter loadImage(String key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _decode(decode), scale: 1.0);
  }

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(_pngBytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _AsyncKeyIconProvider && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _IconPage extends StatefulWidget {
  // Intentionally non-const constructor usage at call sites to verify
  // underlying pages are not rebuilt on push/pop.
  // ignore: prefer_const_constructors_in_immutables
  _IconPage({required this.name, this.nextRoute});

  final String name;
  final String? nextRoute;

  static final Map<String, int> builds = <String, int>{};
  static final Map<String, int> dependencyChanges = <String, int>{};

  @override
  State<_IconPage> createState() => _IconPageState();
}

class _IconPageState extends State<_IconPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AdaptiveRouteState.maybeOf(context);
    TickerMode.valuesOf(context);
    _IconPage.dependencyChanges[widget.name] =
        (_IconPage.dependencyChanges[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) {
    _IconPage.builds[widget.name] = (_IconPage.builds[widget.name] ?? 0) + 1;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Image(
            key: Key('icon-${widget.name}'),
            image: _AsyncKeyIconProvider('icon-${widget.name}'),
          ),
          if (widget.nextRoute != null)
            TextButton(
              onPressed: () =>
                  AdaptiveRouter.of(context).pushNamed(widget.nextRoute!),
              child: Text('open-from-${widget.name}'),
            ),
        ],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _IconPage.builds.clear();
    _IconPage.dependencyChanges.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets(
    'mobile push and pop keeps icons loaded without blank frames or rebuilds',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = AdaptiveRouter(
        initialLocation: '/home',
        routes: [
          AdaptiveRoute(
            path: '/fullscreen',
            fullscreen: true,
            builder: (context, state) => _IconPage(name: 'fullscreen'),
          ),
          AdaptiveShellRoute(
            builder: (context, shell, child) => Scaffold(
              body: child,
              bottomNavigationBar: shell.isCompact
                  ? const SizedBox(height: 56, child: Text('bar'))
                  : null,
            ),
            branches: [
              AdaptiveBranch(
                routes: [
                  AdaptiveRoute(
                    path: '/home',
                    builder: (context, state) =>
                        _IconPage(name: 'home', nextRoute: '/home/detail'),
                    routes: [
                      AdaptiveRoute(
                        path: 'detail',
                        builder: (context, state) => _IconPage(
                          name: 'detail',
                          nextRoute: '/home/detail/more',
                        ),
                        routes: [
                          AdaptiveRoute(
                            path: 'more',
                            builder: (context, state) =>
                                _IconPage(name: 'more'),
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

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      RawImage homeRawImage() => tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(const Key('icon-home')),
          matching: find.byType(RawImage),
        ),
      );

      expect(homeRawImage().image, isNotNull);
      final initialHomeBuilds = _IconPage.builds['home']!;
      final initialHomeDeps = _IconPage.dependencyChanges['home']!;

      // Push cover detail page (/home/detail)
      await tester.tap(find.text('open-from-home'));
      await tester.pumpAndSettle();
      expect(router.location.value, '/home/detail');

      // Pop back to /home: even on the very first frame of pop, the icon must
      // still have its decoded ui.Image (never null / blank) and no extra rebuilds.
      router.pop();
      await tester.pump();
      expect(homeRawImage().image, isNotNull);
      await tester.pumpAndSettle();
      expect(homeRawImage().image, isNotNull);
      expect(_IconPage.builds['home'], initialHomeBuilds);
      expect(_IconPage.dependencyChanges['home'], initialHomeDeps);

      // Push detail -> push more -> pop back to detail
      await tester.tap(find.text('open-from-home'));
      await tester.pumpAndSettle();
      RawImage detailRawImage() => tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(const Key('icon-detail')),
          matching: find.byType(RawImage),
        ),
      );
      expect(detailRawImage().image, isNotNull);
      final initialDetailBuilds = _IconPage.builds['detail']!;
      final initialDetailDeps = _IconPage.dependencyChanges['detail']!;

      await tester.tap(find.text('open-from-detail'));
      await tester.pumpAndSettle();
      expect(router.location.value, '/home/detail/more');

      router.pop();
      await tester.pump();
      expect(detailRawImage().image, isNotNull);
      await tester.pumpAndSettle();
      expect(detailRawImage().image, isNotNull);
      expect(_IconPage.builds['detail'], initialDetailBuilds);
      expect(_IconPage.dependencyChanges['detail'], initialDetailDeps);
    },
  );
}
