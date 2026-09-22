import 'package:material_ui/material_ui.dart';

class MinePage extends StatefulWidget {
  const new({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Mine Page')));
  }
}
