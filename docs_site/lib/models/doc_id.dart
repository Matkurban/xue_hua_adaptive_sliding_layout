/// Navigation groups shown in the sidebar tree.
enum DocGroup { gettingStarted, guides, migration, reference }

/// Every documentation page has a typed identifier. URLs, navigation,
/// prev/next links and content lookups are all derived from this enum,
/// so there are no hand-written path strings anywhere else.
enum DocId {
  quickStart('quick-start', DocGroup.gettingStarted),
  installation('installation', DocGroup.gettingStarted),
  urlStackPanes('url-stack-panes', DocGroup.gettingStarted),
  routeTable('route-table', DocGroup.guides),
  navigationVerbs('navigation-verbs', DocGroup.guides),
  readingState('reading-state', DocGroup.guides),
  customizingUi('customizing-ui', DocGroup.guides),
  layoutWithoutRouter('layout-without-router', DocGroup.guides),
  exampleScenarios('example-scenarios', DocGroup.guides),
  migrating2x('migrating-from-2x', DocGroup.migration),
  migratingGoRouter('migrating-from-go-router', DocGroup.migration),
  caveats('caveats', DocGroup.reference),
  packageSkills('package-skills', DocGroup.reference);

  const DocId(this.slug, this.group);

  final String slug;
  final DocGroup group;

  DocId? get previous => index > 0 ? values[index - 1] : null;
  DocId? get next => index < values.length - 1 ? values[index + 1] : null;

  static Iterable<DocId> inGroup(DocGroup group) => values.where((d) => d.group == group);
}
