import 'package:contact_list_view/contact_list_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/contact.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/contact_services.dart';

class ContactsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('联系人')),
      body: SignalBuilder(
        builder: (context) {
          final contacts = ContactServices.instance.contacts.value;
          return ContactListView<Contact>(
            contactsList: contacts,
            itemExtent: 64,
            startItemExtent: 0,
            endItemExtent: 0,
            tag: _tag,
            itemBuilder: (contact) {
              return ListTile(
                title: Text(contact.name),
                subtitle: Text(contact.phone),
                onTap: () {
                  final router = AdaptiveRouter.of(context);
                  router.pushNamed(
                    router.namedLocation(
                      RouterNames.contact,
                      pathParameters: {'id': '${contact.id}'},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 索引用姓名首字母。不是 A–Z 时归到 #。
String _tag(Contact contact) {
  final name = contact.name.trim();
  if (name.isEmpty) return '#';
  final letter = name[0].toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
}
