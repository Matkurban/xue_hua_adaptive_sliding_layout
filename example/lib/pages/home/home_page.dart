import 'package:breakpoint/breakpoint.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';

class HomePage extends SignalStatefulWidget {
  const new({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ///最上面轮播图的链接
  final List<String> carusolImgs = [
    'https://picsum.photos/seed/p30_img1/800/800',
    'https://picsum.photos/seed/p30_img2/800/800',
    'https://picsum.photos/seed/p30_img3/800/800',
  ];

  ///当前选中的分类
  final FlutterSignal<int> currentCategory = signal(0);

  late final Map<int, ReadonlySignal<bool>> computedSeleted = {
    for (int i = 0; i < mockCategories.length; i++)
      i: computed(() => currentCategory.value == i),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('首页')),
      body: BreakpointBuilder(
        builder: (context, breakpoint) {
          final crossAxisCount = switch (breakpoint.columns) {
            >= 12 => 4,
            >= 8 => 3,
            _ => 2,
          };
          return SignalBuilder(
            builder: (context) {
              final category = mockCategories[currentCategory.value];
              final products = [
                for (final product in mockProducts)
                  if (product.category == category) product,
              ];
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: .symmetric(horizontal: 8),
                      child: AspectRatio(
                        aspectRatio: 21 / 9,
                        child: CarouselView.weightedBuilder(
                          itemCount: carusolImgs.length,
                          infinite: true,
                          flexWeights: [1, 7, 1],
                          itemBuilder: (context, index) {
                            return Card(
                              margin: .symmetric(horizontal: 4),
                              child: Image(
                                image: NetworkImage(carusolImgs[index]),
                                fit: .fill,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: .horizontal,
                        itemCount: mockCategories.length,
                        padding: .symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final seleted = computedSeleted[index]!.value;
                          return InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => currentCategory.value = index,
                            child: Padding(
                              padding: .symmetric(horizontal: 6, vertical: 4),
                              child: Center(
                                child: Text(
                                  mockCategories[index],
                                  style: TextStyle(
                                    color: seleted ? theme.primaryColor : null,
                                    fontWeight: .w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: .fromLTRB(8, 12, 8, 8),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              final router = AdaptiveRouter.of(context);
                              router.pushNamedAndRemoveUntil(
                                router.namedLocation(
                                  RouterNames.product,
                                  pathParameters: {'id': '${product.id}'},
                                ),
                                (match) =>
                                    match.matchedLocation == RouterNames.home,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                Expanded(
                                  child: Image(
                                    image: NetworkImage(product.cover),
                                    fit: .cover,
                                  ),
                                ),
                                Padding(
                                  padding: .all(8),
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: .ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '¥${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: .w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
