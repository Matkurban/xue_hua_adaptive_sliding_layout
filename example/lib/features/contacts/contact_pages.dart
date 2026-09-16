import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/demo_data.dart';

/// 联系人编辑是否未保存，供 [AdaptiveRoute.onExit] 读取。
final Signal<bool> contactEditDirty = signal(false);

/// 联系人列表。搜索框通过 `pushReplacementNamed` 把 `q` 写进 URL。
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.query});

  final String query;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final q = widget.query.toLowerCase();
    final filtered = [
      for (final contact in contacts)
        if (q.isEmpty ||
            contact.name.toLowerCase().contains(q) ||
            contact.email.toLowerCase().contains(q))
          contact,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('contacts-search'),
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search — pushReplacementNamed writes ?q=',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                router.pushReplacementNamed(
                  value.isEmpty ? '/contacts' : '/contacts?q=${Uri.encodeQueryComponent(value)}',
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final contact in filtered)
                  ListTile(
                    key: Key('contact-${contact.id}'),
                    leading: CircleAvatar(child: Text(contact.name[0])),
                    title: Text(contact.name),
                    subtitle: Text(contact.email),
                    onTap: () => router.pushNamed(
                      router.namedLocation(
                        'contact',
                        pathParameters: {'id': contact.id},
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 联系人详情。`await pushNamed<bool>(edit)` 带返回值。
class ContactDetailPage extends StatelessWidget {
  const ContactDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    final contact = contactById(id);
    return Scaffold(
      appBar: AppBar(title: Text(contact?.name ?? 'Contact')),
      body: ListView(
        children: [
          ListTile(
            title: Text(contact?.email ?? id),
            subtitle: const Text('namedLocation + pushNamed'),
          ),
          ListTile(
            key: const Key('edit-contact'),
            title: const Text('Edit'),
            subtitle: const Text('await pushNamed<bool> — pop(true) on save'),
            onTap: () async {
              final saved = await router.pushNamed<bool>('/contacts/$id/edit');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(saved == true ? 'Saved' : 'Dismissed')),
              );
            },
          ),
          ListTile(
            key: const Key('contact-photo'),
            title: const Text('Avatar photo'),
            subtitle: const Text('pushNamed fullscreen'),
            onTap: () => router.pushNamed('/photo/${contact?.photoId ?? id}'),
          ),
        ],
      ),
    );
  }
}

/// 编辑页。AppBar 返回走 maybePop（onExit）；按钮 pop 强退。
class ContactEditPage extends StatefulWidget {
  const ContactEditPage({super.key, required this.id});

  final String id;

  @override
  State<ContactEditPage> createState() => ContactEditPageState();
}

/// 暴露 [dirty] 给 onExit。
class ContactEditPageState extends State<ContactEditPage> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    contactEditDirty.value = false;
    controller = TextEditingController(text: contactById(widget.id)?.name ?? '');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AdaptiveRouter.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit contact')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('edit-name'),
              controller: controller,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => contactEditDirty.value = true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save-contact'),
              onPressed: () {
                contactEditDirty.value = false;
                router.pop(true);
              },
              child: const Text('Save (pop true)'),
            ),
            TextButton(
              key: const Key('discard-contact'),
              onPressed: () {
                contactEditDirty.value = false;
                router.pop(false);
              },
              child: const Text('Discard (pop, skip onExit)'),
            ),
          ],
        ),
      ),
    );
  }
}
