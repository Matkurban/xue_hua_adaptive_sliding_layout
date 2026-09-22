import 'package:signals_flutter/signals_core.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/model/domains/contact.dart';

/// 联系人数据。列表、详情和编辑页共用这一份。
class ContactServices {
  ContactServices._();

  static final ContactServices instance = ContactServices._();

  /// 全部联系人，按姓名排序。
  final ListSignal<Contact> contacts = listSignal(
    List<Contact>.of(mockContacts),
  );

  /// 编辑页是否改过备注。路由 onExit 用它决定要不要确认离开。
  final Signal<bool> remarkDirty = signal(false);

  /// 按 [id] 查找联系人。找不到返回 null。
  Contact? find(int id) {
    for (final contact in contacts.value) {
      if (contact.id == id) return contact;
    }
    return null;
  }

  /// 把 [id] 对应联系人的备注换成 [remark]。找不到则不动。
  void updateRemark(int id, String remark) {
    final index = contacts.value.indexWhere((item) => item.id == id);
    if (index < 0) return;
    contacts[index] = contacts[index].copyWith(remark: remark);
  }
}
