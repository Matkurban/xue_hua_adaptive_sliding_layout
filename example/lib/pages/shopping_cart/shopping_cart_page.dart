import 'package:material_ui/material_ui.dart';

class ShoppingCartPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Shopping Cart')));
  }
}
