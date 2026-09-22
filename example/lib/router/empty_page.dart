import 'package:material_ui/material_ui.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.web_asset_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
