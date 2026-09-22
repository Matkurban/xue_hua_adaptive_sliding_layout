/// 网页顶部的宽度预设，让桌面访客不用缩放窗口就能看 Phone / Tablet / Desktop。
enum SizePreset {
  phone(480, 'Phone'),
  foldable(720, 'Foldable'),
  tablet(1023, 'Tablet'),
  desktop(null, 'Desktop');

  const SizePreset(this.width, this.label);

  /// null 表示占满窗口。
  final double? width;
  final String label;
}
