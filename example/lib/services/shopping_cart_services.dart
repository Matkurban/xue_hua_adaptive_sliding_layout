import 'package:signals_flutter/signals_core.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/cart_item.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';

/// 购物车。详情页加入，购物车页改数量和删除。
class ShoppingCartServices {
  ShoppingCartServices._();

  static final ShoppingCartServices instance = ShoppingCartServices._();

  /// 购物车中的商品行。
  final ListSignal<CartItem> cartProducts = listSignal(<CartItem>[]);

  /// 总金额：每行单价乘以件数之和。
  late final ReadonlySignal<double> total = computed(() {
    var sum = 0.0;
    for (final item in cartProducts.value) {
      sum += item.product.price * item.quantity;
    }
    return sum;
  });

  /// 加入 [product]。已经在购物车里则件数加 1。
  void add(Product product) {
    final index = _indexOf(product.id);
    if (index < 0) {
      cartProducts.add(CartItem(product: product, quantity: 1));
      return;
    }
    final item = cartProducts[index];
    cartProducts[index] = item.copyWith(quantity: item.quantity + 1);
  }

  /// 把 [productId] 的件数加 1。不在购物车里则不动。
  void increase(int productId) {
    final index = _indexOf(productId);
    if (index < 0) return;
    final item = cartProducts[index];
    cartProducts[index] = item.copyWith(quantity: item.quantity + 1);
  }

  /// 把 [productId] 的件数减 1，最少保留 1。不在购物车里则不动。
  void decrease(int productId) {
    final index = _indexOf(productId);
    if (index < 0) return;
    final item = cartProducts[index];
    if (item.quantity <= 1) return;
    cartProducts[index] = item.copyWith(quantity: item.quantity - 1);
  }

  /// 按 [productId] 删除一整行。找不到则不动。
  void remove(int productId) {
    cartProducts.removeWhere((item) => item.product.id == productId);
  }

  int _indexOf(int productId) {
    return cartProducts.value.indexWhere(
      (item) => item.product.id == productId,
    );
  }
}
