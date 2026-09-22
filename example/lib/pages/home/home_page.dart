import 'package:material_ui/material_ui.dart';
import 'package:breakpoint/breakpoint.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';

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
      appBar: AppBar(title: Text('Home Page')),
      body: BreakpointBuilder(
        builder: (context, breakpoint) {
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
                      return SignalBuilder(
                        builder: (context) {
                          bool seleted = computedSeleted[index]!.value;
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
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
