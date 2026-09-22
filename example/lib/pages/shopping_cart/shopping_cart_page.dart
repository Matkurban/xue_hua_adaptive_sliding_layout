import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/shopping_cart_services.dart';

class ShoppingCartPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ShoppingCartServices.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: SignalBuilder(
        builder: (context) {
          final items = cart.cartProducts.value;
          return Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('购物车是空的'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: .symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              crossAxisAlignment: .start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: NetworkImage(item.product.cover),
                                    width: 72,
                                    height: 72,
                                    fit: .cover,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        maxLines: 2,
                                        overflow: .ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '¥${item.product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                cart.decrease(item.product.id),
                                            icon: const Icon(Icons.remove),
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            onPressed: () =>
                                                cart.increase(item.product.id),
                                            icon: const Icon(Icons.add),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: '删除',
                                            onPressed: () =>
                                                cart.remove(item.product.id),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Material(
                elevation: 2,
                child: Padding(
                  padding: .symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text('总金额'),
                      const Spacer(),
                      Text(
                        '¥${cart.total.value.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: .w600,
                        ),
                      ),
                    ],
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
