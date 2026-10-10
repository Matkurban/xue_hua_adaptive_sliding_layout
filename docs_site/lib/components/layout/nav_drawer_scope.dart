import 'package:jaspr/jaspr.dart';

/// Shares the mobile drawer state between the Header (menu button) and the
/// DocLayout (sidebar drawer) without coupling them to each other.
class NavDrawerScope extends InheritedComponent {
  const NavDrawerScope({required this.isOpen, required this.onToggle, required this.onClose, required super.child});

  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onClose;

  static NavDrawerScope of(BuildContext context) {
    final scope = context.dependOnInheritedComponentOfExactType<NavDrawerScope>();
    assert(scope != null, 'No NavDrawerScope found.');
    return scope!;
  }

  @override
  bool updateShouldNotify(NavDrawerScope oldComponent) => oldComponent.isOpen != isOpen;
}
