import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/router/router_names.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/contact_services.dart';

/// 联系人详情。右上角进入备注编辑，也可以切到下一位或回到列表。
class ContactDetailPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = int.tryParse(
      AdaptiveRouteState.of(context).pathParameters['id'] ?? '',
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: const Text('联系人详情'),
        actions: [
          if (id != null)
            IconButton(
              tooltip: '编辑备注',
              onPressed: () async {
                final router = AdaptiveRouter.of(context);
                await router.pushNamed<String>(
                  router.namedLocation(
                    RouterNames.contactEdit,
                    pathParameters: {'id': '$id'},
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: id == null
          ? const Center(child: Text('没有这个联系人'))
          : SignalBuilder(
              builder: (context) {
                final contacts = ContactServices.instance;
                final contact = contacts.find(id);
                if (contact == null) {
                  return const Center(child: Text('没有这个联系人'));
                }
                final list = contacts.contacts.value;
                final index = list.indexWhere((item) => item.id == contact.id);
                final next = index >= 0 && index < list.length - 1
                    ? list[index + 1]
                    : null;
                return ListView(
                  padding: .all(16),
                  children: [
                    Text(contact.name, style: theme.textTheme.headlineSmall),
                    SizedBox(height: 16),
                    ListTile(
                      title: const Text('电话'),
                      subtitle: Text(contact.phone),
                    ),
                    ListTile(
                      title: const Text('邮箱'),
                      subtitle: Text(contact.email),
                    ),
                    ListTile(
                      title: const Text('公司'),
                      subtitle: Text(contact.company),
                    ),
                    ListTile(
                      title: const Text('备注'),
                      subtitle: Text(contact.remark),
                    ),
                    SizedBox(height: 24),
                    if (next != null)
                      FilledButton(
                        onPressed: () {
                          final router = AdaptiveRouter.of(context);
                          router.popAndPushNamed(
                            router.namedLocation(
                              RouterNames.contact,
                              pathParameters: {'id': '${next.id}'},
                            ),
                          );
                        },
                        child: Text('下一位：${next.name}'),
                      ),
                    SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        final router = AdaptiveRouter.of(context);
                        if (!router.canPop()) return;
                        router.popUntil(
                          (match) =>
                              match.matchedLocation == RouterNames.contacts,
                        );
                      },
                      child: const Text('回到列表'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
