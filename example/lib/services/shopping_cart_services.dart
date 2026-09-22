import 'package:signals_flutter/signals_core.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';

///购物车服务类
class ShoppingCartServices {
  ShoppingCartServices._();

  static final ShoppingCartServices instance = ShoppingCartServices._();

  ///购物车中的商品
  final ListSignal<Product> cartProducts = listSignal([]);
}
