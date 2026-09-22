import 'package:material_ui/material_ui.dart';

class ContactsPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Contacts Page')));
  }
}
