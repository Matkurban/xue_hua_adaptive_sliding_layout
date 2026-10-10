import 'doc_id.dart';

/// A node of the sidebar tree.
class NavGroup {
  const NavGroup(this.group, this.items);
  final DocGroup group;
  final List<NavLeaf> items;
}

class NavLeaf {
  const NavLeaf(this.id, this.label);
  final DocId id;
  final String label;
}
