/// Navigation groups shown in the sidebar tree, in reading order.
enum DocGroup { gettingStarted, tutorial, reference, migration, ai }

/// Every documentation page has a typed identifier. URLs, navigation,
/// prev/next links and content lookups are all derived from this enum,
/// so there are no hand-written path strings anywhere else.
///
/// The declaration order is the reading order: each tutorial page builds on
/// the previous one, and the pager follows this order.
enum DocId {
  introduction('introduction', DocGroup.gettingStarted),
  installation('installation', DocGroup.gettingStarted),
  firstApp('first-app', DocGroup.gettingStarted),
  nestedRoutes('nested-routes', DocGroup.tutorial),
  navigation('navigation', DocGroup.tutorial),
  tabs('tabs', DocGroup.tutorial),
  twoColumns('two-columns', DocGroup.tutorial),
  titlesBreadcrumbs('titles-and-breadcrumbs', DocGroup.tutorial),
  redirectsOnExit('redirects-and-on-exit', DocGroup.tutorial),
  customizingUi('customizing-ui', DocGroup.tutorial),
  readingState('reading-state', DocGroup.tutorial),
  layoutWithoutRouter('layout-without-router', DocGroup.tutorial),
  routeTable('route-table', DocGroup.reference),
  navigationVerbs('navigation-verbs', DocGroup.reference),
  caveats('caveats', DocGroup.reference),
  exampleApp('example-app', DocGroup.reference),
  migratingGoRouter('migrating-from-go-router', DocGroup.migration),
  skills('skills', DocGroup.ai);

  const DocId(this.slug, this.group);

  final String slug;
  final DocGroup group;

  DocId? get previous => index > 0 ? values[index - 1] : null;
  DocId? get next => index < values.length - 1 ? values[index + 1] : null;

  static Iterable<DocId> inGroup(DocGroup group) => values.where((d) => d.group == group);
}
