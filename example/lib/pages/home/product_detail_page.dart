import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/shopping_cart_services.dart';

/// 商品详情。展示在首页右栏，或窄屏盖住底栏的下一页。
class ProductDetailPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = int.tryParse(
      AdaptiveRouteState.of(context).pathParameters['id'] ?? '',
    );
    final product = id == null ? null : findMockProduct(id);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: Text(product?.name ?? '商品'),
      ),
      body: product == null
          ? const Center(child: Text('没有这个商品'))
          : ListView(
              padding: .only(bottom: 24),
              children: [
                AspectRatio(
                  aspectRatio: 21 / 9,
                  child: CarouselView.weightedBuilder(
                    itemCount: product.imgs.length,
                    infinite: product.imgs.length > 1,
                    flexWeights: const [1, 7, 1],
                    itemBuilder: (context, index) {
                      return Card(
                        margin: .symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            final router = AdaptiveRouter.of(context);
                            router.pushNamed(
                              router.namedLocation(
                                RouterNames.preview,
                                pathParameters: {'id': '${product.id}'},
                                queryParameters: {'index': index},
                              ),
                            );
                          },
                          child: Image(
                            image: NetworkImage(product.imgs[index]),
                            fit: .cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: .fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Text(product.name, style: theme.textTheme.titleLarge),
                      SizedBox(height: 8),
                      Text(
                        '¥${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(label: Text(product.category)),
                      ),
                      SizedBox(height: 12),
                      Text(product.remark, style: theme.textTheme.bodyLarge),
                      SizedBox(height: 8),
                      Text(product.description),
                      SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          ShoppingCartServices.instance.add(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入购物车')),
                          );
                        },
                        child: const Text('加入购物车'),
                      ),
                      SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          AdaptiveRouter.of(context)
                              .pushNamed(RouterNames.shopping);
                        },
                        child: const Text('去购物车'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
