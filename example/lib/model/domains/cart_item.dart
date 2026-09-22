import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';

/// 购物车里的一行：哪个商品、买几件。
class CartItem {
  /// [product] 为商品，[quantity] 为件数，至少为 1。
  CartItem({required this.product, required this.quantity});

  /// 商品。
  final Product product;

  /// 件数。
  final int quantity;

  /// 用新的 [quantity] 复制一行。不传则保持原件数。
  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}
