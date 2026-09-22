/// 通讯录里的一条联系人。备注可被编辑页替换。
class Contact {
  /// [id] 唯一；[name] 的首字母用于字母索引。
  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.company,
    required this.remark,
  });

  /// 联系人 ID。
  final int id;

  /// 姓名。首字母必须是 A–Z，索引条才按字母分组。
  final String name;

  /// 电话。
  final String phone;

  /// 邮箱。
  final String email;

  /// 公司。
  final String company;

  /// 备注。
  final String remark;

  /// 用新的 [remark] 复制一条。不传则保持原备注。
  Contact copyWith({String? remark}) {
    return Contact(
      id: id,
      name: name,
      phone: phone,
      email: email,
      company: company,
      remark: remark ?? this.remark,
    );
  }
}

/// 约 50 条假联系人。前 24 个字母各两条，Y、Z 各一条，保证 26 个字母都有。
final List<Contact> mockContacts = _mockContacts();

List<Contact> _mockContacts() {
  final contacts = <Contact>[];
  var id = 1;
  for (var letter = 0; letter < 26; letter++) {
    final initial = String.fromCharCode(65 + letter);
    final count = letter < 24 ? 2 : 1;
    for (var n = 0; n < count; n++) {
      final name = n == 0 ? '${initial}lex' : '${initial}nna';
      contacts.add(
        Contact(
          id: id,
          name: name,
          phone: '138${id.toString().padLeft(8, '0')}',
          email: '${name.toLowerCase()}@example.com',
          company: '$initial 示例公司',
          remark: '同事',
        ),
      );
      id++;
    }
  }
  contacts.sort((a, b) => a.name.compareTo(b.name));
  return contacts;
}
