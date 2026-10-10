/// Design tokens shared by the stylesheet. Breakpoints are referenced from
/// Dart so layout rules and docs stay in sync.
abstract final class Breakpoints {
  static const int drawer = 900; // below: sidebar becomes a drawer
  static const int toc = 1200; // above: right TOC visible
}

abstract final class Layout {
  static const int headerHeight = 60;
  static const int sidebarWidth = 272;
  static const int tocWidth = 224;
  static const int contentMax = 780;
}
