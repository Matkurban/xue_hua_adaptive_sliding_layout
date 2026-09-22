import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/product.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/shopping_cart_services.dart';

void main() {
  group('ShoppingCartServices', () {
    final cart = ShoppingCartServices.instance;
    final product = mockProducts.first;

    setUp(() {
      cart.cartProducts.clear();
    });

    test('加入同一商品会累加数量和总金额', () {
      cart.add(product);
      cart.add(product);
      expect(cart.cartProducts.single.quantity, 2);
      expect(cart.total.value, product.price * 2);
    });

    test('增加和减少数量，最少为 1', () {
      cart.add(product);
      cart.increase(product.id);
      expect(cart.cartProducts.single.quantity, 2);
      cart.decrease(product.id);
      cart.decrease(product.id);
      expect(cart.cartProducts.single.quantity, 1);
      expect(cart.total.value, product.price);
    });

    test('删除后总金额归零', () {
      cart.add(product);
      cart.remove(product.id);
      expect(cart.cartProducts, isEmpty);
      expect(cart.total.value, 0);
    });
  });
}
