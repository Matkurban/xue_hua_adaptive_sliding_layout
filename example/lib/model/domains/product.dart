export 'mock_products.dart';

class Product {
  /// 商品 ID
  final int id;

  /// 商品名称
  final String name;

  /// 商品描述
  final String description;

  /// 商品分类
  final String category;

  /// 商品封面
  final String cover;

  /// 商品图片
  final List<String> imgs;

  /// 商品价格
  final double price;

  /// 商品备注
  final String remark;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.cover,
    required this.imgs,
    required this.price,
    required this.remark,
  });
}
