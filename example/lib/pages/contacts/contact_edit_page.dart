import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/services/contact_services.dart';

/// 修改联系人备注。返回走 maybePop，因此未保存时会触发路由 onExit。
class ContactEditPage extends StatefulWidget {
  const new({super.key});

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  final TextEditingController _controller = TextEditingController();
  var _ready = false;
  var _contactId = 0;
  var _origin = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final id = int.tryParse(
      AdaptiveRouteState.of(context).pathParameters['id'] ?? '',
    );
    _contactId = id ?? 0;
    final contact = id == null ? null : ContactServices.instance.find(id);
    _origin = contact?.remark ?? '';
    _controller.text = _origin;
    ContactServices.instance.remarkDirty.value = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contact = ContactServices.instance.find(_contactId);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => AdaptiveRouter.of(context).maybePop(),
        ),
        title: const Text('编辑备注'),
        actions: [
          TextButton(
            onPressed: contact == null
                ? null
                : () {
                    ContactServices.instance.updateRemark(
                      _contactId,
                      _controller.text,
                    );
                    ContactServices.instance.remarkDirty.value = false;
                    AdaptiveRouter.of(context).pop(_controller.text);
                  },
            child: const Text('保存'),
          ),
        ],
      ),
      body: contact == null
          ? const Center(child: Text('没有这个联系人'))
          : Padding(
              padding: .all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: '备注'),
                onChanged: (value) {
                  ContactServices.instance.remarkDirty.value = value != _origin;
                },
              ),
            ),
    );
  }
}
