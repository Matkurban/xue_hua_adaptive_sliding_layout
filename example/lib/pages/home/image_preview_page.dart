import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';

/// 商品图片全屏预览。盖住壳，点返回或遮罩关闭。
class ImagePreviewPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  PageController? _controller;
  List<String> _images = const [];
  final FlutterSignal<int> _index = signal(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final state = AdaptiveRouteState.of(context);
    final id = int.tryParse(state.pathParameters['id'] ?? '');
    final product = id == null ? null : findMockProduct(id);
    _images = product?.imgs ?? const [];
    final requested = int.tryParse(state.queryParameters['index'] ?? '') ?? 0;
    final initial = _images.isEmpty
        ? 0
        : requested.clamp(0, _images.length - 1);
    _index.value = initial;
    _controller = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: BackButton(
          color: primary,
          style: IconButton.styleFrom(foregroundColor: primary),
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: SignalBuilder(
          builder: (context) {
            if (_images.isEmpty) return const Text('图片预览');
            return Text('${_index.value + 1}/${_images.length}');
          },
        ),
      ),
      body: controller == null || _images.isEmpty
          ? const Center(
              child: Text('没有图片', style: TextStyle(color: Colors.white)),
            )
          : PageView.builder(
              controller: controller,
              itemCount: _images.length,
              onPageChanged: (value) => _index.value = value,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image(
                    image: NetworkImage(_images[index]),
                    fit: .contain,
                  ),
                );
              },
            ),
    );
  }
}
