// Documentation content for xue_hua_adaptive_sliding_layout (English).
// Source of truth: the package README, CHANGELOG, lib/ and example/lib.
import '../models/doc_id.dart';
import '../models/doc_page.dart';

DocPage page(DocId id) => switch (id) {
  DocId.quickStart => const DocPage(
    id: DocId.quickStart,
    title: 'Quick Start',
    description: 'Declare one route table, hand it to MaterialApp.router, and navigate with Navigator-style verbs.',
    blocks: [
      DocParagraph(
        'Declarative adaptive routing for Flutter. **One route table** maps a URL to a page stack and a 1- or 2-column sliding layout. Call sites look like `Navigator`: `AdaptiveRouter.of(context).pushNamed(...)`.',
      ),
      DocParagraph(
        'The host holds the `AdaptiveRouter` instance — no service locator. Extra dependencies: `signals_flutter`, `material_ui`.',
      ),
      DocHeading('route-table', 'Declare the route table'),
      DocCode(CodeLanguage.dart, r'''
final router = AdaptiveRouter(
  initialLocation: '/mail',
  routes: [
    AdaptiveShellRoute(
      builder: (context, shell, child) {
        if (!shell.isCompact) return Scaffold(body: child);
        return AdaptiveShellChrome(
          bottomNavigationBar: (context) => NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.mail), label: 'Mail'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Contacts'),
            ],
          ),
          child: child,
        );
      },
      branches: [
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/mail',
            title: (_) => 'Mail',
            builder: (context, state) => const MailPage(),
            routes: [
              AdaptiveRoute(
                path: ':folder',
                builder: (context, state) =>
                    FolderPage(folder: state.pathParameters['folder']!),
              ),
            ],
          ),
        ]),
        AdaptiveBranch(routes: [
          AdaptiveRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsPage(),
          ),
        ]),
      ],
    ),
  ],
);

MaterialApp.router(routerConfig: router);'''),
      DocHeading('navigate', 'Navigate from a page'),
      DocCode(CodeLanguage.dart, r'''
final router = AdaptiveRouter.of(context);
router.pushNamed('/mail/inbox');
router.pushNamed(
  router.namedLocation('thread', pathParameters: {'folder': 'inbox', 'threadId': '42'}),
  arguments: thread,
);
router.pop();'''),
      DocCallout(
        CalloutKind.tip,
        'The example app is the integration template: copy its route table from `example/lib/router/router_pages.dart`.',
      ),
      DocHeading('next', 'Next steps'),
      DocList([
        'See how a location becomes a page stack in [URL → stack → panes](doc:url-stack-panes).',
        'Every route option is listed in [Route table](doc:route-table).',
      ]),
    ],
  ),
  DocId.installation => const DocPage(
    id: DocId.installation,
    title: 'Installation',
    description: 'SDK requirements, dependencies and how to add the package.',
    blocks: [
      DocHeading('requirements', 'Requirements'),
      DocTable(
        ['Item', 'Constraint'],
        [
          ['Dart SDK', '`^3.13.0`'],
          ['Flutter', '`>=3.47.0`'],
          ['Dependencies', '`signals_flutter: ^7.1.0`, `material_ui: ^1.6.0`'],
        ],
      ),
      DocHeading('add', 'Add the package'),
      DocCode(CodeLanguage.shell, 'flutter pub add xue_hua_adaptive_sliding_layout'),
      DocCode(CodeLanguage.yaml, '''
dependencies:
  xue_hua_adaptive_sliding_layout: ^3.4.3''', fileName: 'pubspec.yaml'),
      DocCode(
        CodeLanguage.dart,
        "import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';",
      ),
      DocHeading('run-example', 'Run the example'),
      DocCode(CodeLanguage.shell, '''
cd example && flutter run -d chrome
cd example && flutter test'''),
      DocHeading('tests', 'Run the package tests'),
      DocCode(CodeLanguage.shell, '''
flutter analyze && flutter test
cd example && flutter analyze && flutter test'''),
    ],
  ),
  DocId.urlStackPanes => const DocPage(
    id: DocId.urlStackPanes,
    title: 'URL → Stack → Panes',
    description: 'How a location is matched into a page stack and laid out as one Navigator or two sliding panes.',
    blocks: [
      DocCode(CodeLanguage.plain, '''
URL /mail/inbox/42/reply
  → RouteInformationParser
  → MatchList [mail, inbox, 42, reply]
  → RouterDelegate → AdaptiveShellRoute.builder
      window width < 840   → 1 column: Navigator pages
      window width >= 840  → 2 columns: SlidingPaneViewport (last 2 panes)
  → fullscreen / off-shell routes → root Navigator'''),
      DocHeading('stack', 'The match list is the stack'),
      DocParagraph(
        'A location such as `/mail/inbox/42/reply` walks the route tree and produces a list of matches. That list **is** the page stack.',
      ),
      DocHeading('panes', 'One column or two'),
      DocParagraph(
        'Below `expandedMinWidth` (default 840) it is a classic `Navigator`. At or above it, the last two matches sit side by side in `SlidingPaneViewport`; deeper pages slide older ones off to the left.',
      ),
      DocParagraph(
        '`fullscreen: true` and `fullscreenDialog: true` matches stack on the **root** Navigator (login, photo, compose dialogs).',
      ),
      DocHeading('web', 'Back, deep links and the web'),
      DocParagraph(
        'Browser back, deep links, and refresh all change the location and take the same path. Web uses the default **hash** strategy (`/#/mail/inbox/42`), so GitHub Pages needs no 404 fallback.',
      ),
    ],
  ),
  DocId.routeTable => const DocPage(
    id: DocId.routeTable,
    title: 'Route Table',
    description:
        'AdaptiveRouter, AdaptiveRoute, AdaptiveShellRoute, AdaptiveBranch and the state objects passed to builders.',
    blocks: [
      DocHeading('types', 'Types'),
      DocTable(
        ['Type', 'Role'],
        [
          [
            '`AdaptiveRouter`',
            '`RouterConfig<AdaptiveRouteMatchList>`. Verbs + `namedLocation` / `refresh`. Signals: `location`, `matches`, `currentBranch`. `of` / `maybeOf`.',
          ],
          [
            '`AdaptiveRoute`',
            'One page. `path`, optional `name`, `builder`, `title`, `fullscreen`, `fullscreenDialog`, `hidesBottomBarWhenPushed`, `opaque`, `barrierColor`, `barrierDismissible`, `transitionsBuilder`, `redirect`, `onExit`, nested `routes`.',
          ],
          [
            '`AdaptiveShellRoute`',
            'Tabs + adaptive chrome. One per tree, top-level only. `builder(context, shell, child)`, `branches`, `breakpoints`, sash / breadcrumbs, plus [UI knobs](doc:customizing-ui).',
          ],
          [
            '`AdaptiveShellChrome`',
            'Compact bottom bar. `bottomNavigationBar` is a `WidgetBuilder`. The bar is inside the branch page, so a sheet with `useRootNavigator: false` covers it. Do not also set `Scaffold.bottomNavigationBar`.',
          ],
          ['`AdaptiveBranch`', 'One tab. `routes`, optional `initialLocation` / `placeholder`.'],
          [
            '`AdaptiveRouteState`',
            'Builder argument, also `AdaptiveRouteState.of(context)`: `uri`, `matchedLocation`, `fullPath`, `name`, `pathParameters`, `queryParameters`, `arguments`, `error`, `pageKey`.',
          ],
          [
            '`AdaptiveShellState`',
            'Shell builder argument: `currentIndex`, width / breakpoints (`isCompact`, `isMedium`, `isExpanded`), `leftPaneFraction`, `goBranch`.',
          ],
          ['`LayoutBreakpoints`', '`const` class, defaults `compactMaxWidth: 600`, `expandedMinWidth: 840`.'],
        ],
      ),
      DocHeading('paths', 'Paths'),
      DocList(['Child paths are relative to their parent.', '`:param` is one path segment.', 'First match wins.']),
      DocCallout(
        CalloutKind.info,
        '`builder` + `transitionsBuilder` supply the page, because wide panes need a `Widget`, not a `Page`.',
      ),
      DocHeading('redirect', 'Redirects and errors'),
      DocParagraph(
        'Top-level `redirect` and per-route `redirect` may return a new location (`FutureOr<String?>`). Loops stop after `redirectLimit` (5) and hit `errorBuilder`. The example guards its account page like this:',
      ),
      DocCode(CodeLanguage.dart, r'''
AdaptiveRouter(
  initialLocation: RouterNames.splash,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path.startsWith(RouterNames.account) &&
        !AppSettingServices.instance.signedIn.value) {
      return '${RouterNames.login}?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    return null;
  },
  errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
  routes: [
    AdaptiveRoute(path: '/', redirect: (_, _) => RouterNames.splash),
    // ...
  ],
)''', fileName: 'example/lib/router/router_pages.dart'),
      DocHeading('on-exit', 'Guarding exit with onExit'),
      DocCode(CodeLanguage.dart, r'''
AdaptiveRoute(
  path: 'edit',
  name: RouterNames.contactEdit,
  onExit: (context, state) async {
    if (!ContactServices.instance.remarkDirty.value) return true;
    final leave = await showDialog<bool>(
      context: context,
      useRootNavigator: AdaptivePaneScope.maybeOf(context) != null,
      builder: (dialogContext) => AlertDialog(/* ... */),
    );
    return leave == true;
  },
  builder: (context, state) => const ContactEditPage(),
)'''),
    ],
  ),
  DocId.navigationVerbs => const DocPage(
    id: DocId.navigationVerbs,
    title: 'Navigation Verbs',
    description: 'Navigator-named verbs, how they behave in one and two columns, tab switching and exit confirmation.',
    blocks: [
      DocParagraph(
        'All names and signatures match `NavigatorState`. `routeName` is a location. There is no non-named `push(Route)` — every page must be in the table so the URL can express it.',
      ),
      DocHeading('verbs', 'Verbs'),
      DocTable(
        ['Call', 'Behavior'],
        [
          [
            '`pushNamed`',
            'Push onto the branch `Navigator`, or overlay the root if `fullscreen` / off-shell. Same-branch prefix extends the stack (`/mail` → `/mail/inbox/42` can slide in two panes). Same-branch non-prefix appends the leaf (`/mail/inbox/41` → `/mail/inbox/42` yields `[mail, inbox, 41, 42]`). Other branch: switch tab and rebuild that stack from the URL.',
          ],
          ['`pushReplacementNamed`', 'Replace stack top. Same-level swap; the right pane updates in place.'],
          [
            '`pushNamedAndRemoveUntil`',
            'Pop while the predicate is false, then `pushNamed`. `(_) => false` rebuilds from the URL (deep link, login return, reset tab).',
          ],
          ['`popAndPushNamed`', '`pop` then `pushNamed`.'],
          [
            '`pop`',
            'Pop immediately. **Does not** call `onExit`. If a dialog / sheet / menu covers the top page, only that layer is closed.',
          ],
          [
            '`maybePop`',
            'Asks the top page\'s `PopScope` first, then the route\'s `onExit`. AppBar back, system back, browser back, and Escape use this. Context-free: it only handles the **top pane** plus root / shell popups that cover everything.',
          ],
          [
            '`popFrom(context)`',
            'Acts on the layer `context` lives in: inside a dialog / sheet it closes that; inside a page it closes the popup covering that page, or pops the page when it is the top page and uncovered. **Does not** call `onExit`.',
          ],
          [
            '`maybePopFrom(context)`',
            'Consultative `popFrom`: a popup gets its own `PopScope`; a page gets `PopScope` → `onExit`.',
          ],
          ['`popUntil`', 'Pop until the predicate is true, not past the branch root.'],
          ['`canPop`', 'Overlay present, or current branch depth > 1.'],
        ],
      ),
      DocParagraph('`pushNamed` returns a `Future` completed by `pop(result)`.'),
      DocHeading('helpers', 'Helpers'),
      DocList([
        '`namedLocation(name, pathParameters:, queryParameters:)` builds a location for the `*Named` verbs.',
        '`refresh()` re-runs redirect after auth changes.',
      ]),
      DocHeading('tabs', 'Switching tabs'),
      DocParagraph(
        'Tab switches are not a Navigator verb. Use `AdaptiveShellState.goBranch(index, {initialLocation})`. Internally that is `pushNamedAndRemoveUntil` to the branch\'s last location (or `initialLocation`). Tapping the **current** tab with `initialLocation: true` returns to the branch root:',
      ),
      DocCode(CodeLanguage.dart, '''
if (index == shell.currentIndex) {
  shell.goBranch(index, initialLocation: true);
} else {
  shell.goBranch(index);
}'''),
      DocHeading('confirm-exit', 'Confirm before exit'),
      DocParagraph(
        'Put `PopScope(canPop: false)` in the shell `builder` (or a tab root page). System back then calls `onPopInvokedWithResult(false)` so you can show a dialog and `SystemNavigator.pop()`.',
      ),
      DocCallout(
        CalloutKind.warning,
        'Use `showDialog(useRootNavigator: false)` so the dialog shares the shell navigator with `PopScope` — a root-navigator dialog would make the next Android back exit the app. Works with Android predictive back. Escape at the root does not trigger this.',
      ),
    ],
  ),
  DocId.readingState => const DocPage(
    id: DocId.readingState,
    title: 'Reading State',
    description: 'Read the location, route parameters, pane and shell scopes, and set breadcrumb titles.',
    blocks: [
      DocCode(CodeLanguage.dart, '''
AdaptiveRouter.of(context).location.value;          // '/mail/inbox/42'
AdaptiveRouteState.of(context).pathParameters;      // {'folder': 'inbox', ...}
AdaptivePaneScope.maybeOf(context)?.title.value = subject; // breadcrumbs
AdaptiveShellScope.maybeOf(context)?.isExpanded;'''),
      DocHeading('pane-scope', 'AdaptivePaneScope'),
      DocParagraph(
        '`AdaptivePaneScope.maybeOf` is non-null only inside a two-column pane. Use it instead of 2.x `inSlidingWindow` / `SlidingPageTitle`. Async titles: write `title.value` when the subject arrives — the package no longer walks the element tree for `AppBar.title`.',
      ),
      DocHeading('route-titles', 'Route titles and localization'),
      DocParagraph(
        '`AdaptiveRoute.title(state)` runs once at match time and has no `BuildContext`; `state.fullPath` is the full pattern and `state.uri` carries the query.',
      ),
      DocList([
        'To localize it, use a context-free lookup — gen-l10n\'s `lookupAppLocalizations(locale)` with `WidgetsBinding.instance.platformDispatcher.locale` (or your own locale signal), or `intl`\'s `Intl.defaultLocale`.',
        'When you need a context, or the title must follow a live locale switch, set `AdaptivePaneScope.maybeOf(context)?.title.value` from the page instead; a static `title` is not re-evaluated when the locale changes.',
      ]),
      DocHeading('signals', 'Subscribing in UI'),
      DocParagraph(
        'Subscribe in UI with `SignalBuilder` (see `signals_flutter`). To draw titles in **your** chrome instead of the built-in strip, read `AdaptiveRouter.of(context).matches.value.branchMatches` (each match has a `title` signal and `name`).',
      ),
    ],
  ),
  DocId.customizingUi => const DocPage(
    id: DocId.customizingUi,
    title: 'Customizing the UI',
    description: 'Builders and value parameters for the viewport, resize handle, breadcrumbs and overlay routes.',
    blocks: [
      DocParagraph(
        'Use **builders** to replace structure, **value parameters** to tweak numbers. Theme colors still come from `Theme.of(context)`. 1-column page transitions use Flutter\'s `ThemeData.pageTransitionsTheme`.',
      ),
      DocHeading('viewport', 'Viewport (SlidingPaneViewport / AdaptiveShellRoute)'),
      DocTable(
        ['Parameter', 'Default', 'Role'],
        [
          ['`slideDuration`', '280ms', 'Column slide'],
          ['`slideCurve`', '`Curves.easeOutCubic`', 'Column slide'],
          [
            '`paneBuilder`',
            '2-col card / 1-col flat',
            'Wrap each column. `index == panes.length` is the empty right slot',
          ],
          [
            '`resizeHandleBuilder`',
            'rounded animated bar',
            '`Widget Function(BuildContext context, bool isHovered)`; highlights with `colorScheme.primary` on hover / drag',
          ],
          ['`resizeHandleWidth`', '4 (shell route)', 'Hit-test width of the handle; required on `SlidingPaneViewport`'],
          ['`resizeHandleMargin`', '—', 'Insets the handle independently of its hit area'],
          ['`placeholder`', 'outline icon', 'Shell-level empty right pane; `AdaptiveBranch.placeholder` wins if set'],
        ],
      ),
      DocParagraph('Default pane split: left fraction 0.4, minimum left / right fraction 0.35.'),
      DocHeading('example-shell', 'Example: the demo shell route'),
      DocCode(CodeLanguage.dart, '''
AdaptiveShellRoute(
  showBreadcrumbs: true,
  resizable: true,
  initialLeftPaneFraction: 0.4,
  placeholder: (context) => const EmptyPage(),
  slideDuration: const Duration(milliseconds: 280),
  resizeHandleBuilder: (context, isHovered) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      height: double.infinity,
      margin: .symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isHovered ? colorScheme.primary : colorScheme.surfaceDim,
      ),
    );
  },
  breadcrumbsBuilder: (context, panes, onSelect) {
    return AdaptiveBreadcrumbs(
      panes: panes,
      onSelect: onSelect,
      height: 32,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  },
  paneBuilder: (context, index, child) {
    return Card(
      margin: .symmetric(horizontal: 8, vertical: 8),
      child: KeyedSubtree(key: const Key('pane-flat'), child: child),
    );
  },
  builder: (context, shell, child) => AppShell(shell: shell, child: child),
  branches: [/* ... */],
)''', fileName: 'example/lib/router/router_pages.dart'),
      DocHeading('breadcrumbs', 'Breadcrumbs'),
      DocTable(
        ['Parameter', 'Default', 'Role'],
        [
          ['`height`', '32', 'Strip height'],
          ['`padding`', 'horizontal 12', 'Strip padding'],
          ['`backgroundColor`', '`surfaceContainerLow`', 'Strip color'],
          ['`itemBuilder`', 'InkWell + Text', 'One crumb'],
          ['`separatorBuilder`', 'chevron', 'Between crumbs'],
          [
            '`AdaptiveShellRoute.breadcrumbsBuilder`',
            '`AdaptiveBreadcrumbs`',
            'Replace the whole strip (`showBreadcrumbs` still gates it)',
          ],
          ['`escapePops`', 'true', 'Escape calls `maybePop`'],
        ],
      ),
      DocHeading('bottom-bar', 'Bottom bar behavior'),
      DocParagraph(
        'On medium / expanded, nested pages keep the host chrome. On compact, pages below the branch root hide the bottom bar by default (`hidesBottomBarWhenPushed`; set `false` to keep it). A bottom sheet on the tab root covers the bar when the shell uses `AdaptiveShellChrome` (`useRootNavigator: false`). `Scaffold.bottomNavigationBar` sits outside the branch navigator, so the same sheet leaves the bar visible.',
      ),
      DocHeading('overlay-routes', 'Overlay routes (AdaptiveRoute)'),
      DocTable(
        ['Parameter', 'Default', 'Role'],
        [
          [
            '`hidesBottomBarWhenPushed`',
            'true',
            'Compact only: the pushed page covers the host bottom bar. Two panes on desktop are untouched',
          ],
          ['`fullscreen`', 'false', 'Root Navigator at every width, normal transition'],
          ['`fullscreenDialog`', 'false', 'Root Navigator at every width as a Material fullscreen dialog'],
          ['`opaque`', 'true', 'With `transitionsBuilder`: transparent photo viewer'],
          ['`barrierColor`', 'null', 'With `transitionsBuilder`'],
          ['`barrierDismissible`', 'false', 'Tap the barrier to pop'],
        ],
      ),
      DocCode(CodeLanguage.dart, '''
AdaptiveRoute(
  path: 'preview',
  name: RouterNames.preview,
  title: (_) => 'Preview',
  fullscreen: true,
  opaque: false,
  barrierColor: Colors.black,
  barrierDismissible: true,
  transitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (context, state) => const ImagePreviewPage(),
)'''),
    ],
  ),
  DocId.layoutWithoutRouter => const DocPage(
    id: DocId.layoutWithoutRouter,
    title: 'Layout Without a Router',
    description: 'Use SlidingPaneViewport, SlidingPane and AdaptiveBreadcrumbs directly, and the width breakpoints.',
    blocks: [
      DocParagraph(
        '`SlidingPaneViewport`, `SlidingPane`, and `AdaptiveBreadcrumbs` stay public if you only want the sliding columns.',
      ),
      DocHeading('widgets', 'Building blocks'),
      DocTable(
        ['Widget', 'Key parameters'],
        [
          [
            '`SlidingPaneViewport`',
            'Required: `panes` (`List<SlidingPane>`), `visibleCount`, `resizeHandleWidth`. Optional: `onPop`, `placeholder`, `leftPaneFraction`, `minLeftPaneFraction`, `minRightPaneFraction`, `onLeftPaneFractionChanged`, `slideDuration`, `slideCurve`, `paneBuilder`, `resizeHandleMargin`, `resizeHandleBuilder`.',
          ],
          [
            '`SlidingPane`',
            '`key` (`LocalKey`, must stay stable as depth changes so pane state survives), `title` (`Signal<String>`), `child`.',
          ],
          [
            '`AdaptiveBreadcrumbs`',
            'Required: `panes`, `onSelect` (called with the tapped pane). Optional: `height`, `padding`, `backgroundColor`, `itemBuilder`, `separatorBuilder`.',
          ],
        ],
      ),
      DocHeading('breakpoints', 'Breakpoints'),
      DocParagraph('Breakpoints are based on window width, not device type:'),
      DocTable(
        ['Width', 'Band', 'Visible columns'],
        [
          ['`< compactMaxWidth` (600)', 'compact', '1 — `Navigator` (full-screen stack)'],
          ['600–839', 'medium', '1 — same `Navigator`; host uses `shell.isMedium` for chrome'],
          ['`≥ expandedMinWidth` (840)', 'expanded', '2 — last two panes + optional sash'],
        ],
      ),
      DocCallout(
        CalloutKind.info,
        'The viewport is 1 or 2 columns. Three-plus columns would require changing `visibleColumnCount` and teaching `SlidingPaneViewport` to lay out N panes.',
      ),
    ],
  ),
  DocId.exampleScenarios => const DocPage(
    id: DocId.exampleScenarios,
    title: 'Example Scenarios',
    description: 'What the example app demonstrates and where to find it.',
    blocks: [
      DocParagraph(
        'The `example/` app is the integration template. On the web demo, the top bar pins phone / foldable / tablet / desktop widths so you can see every breakpoint without resizing the window.',
      ),
      DocHeading('areas', 'Areas'),
      DocTable(
        ['Area', 'What it shows', 'Files'],
        [
          [
            'Auth',
            'Full-screen splash / login / register routes, `redirect` to `/login?from=` for the account page',
            '`pages/auth/`',
          ],
          [
            'Home',
            'Product list → `/home/:id` detail with a `title` resolved from the id, translucent full-screen image preview with `transitionsBuilder`',
            '`pages/home/`',
          ],
          ['Shopping cart', 'A separate branch with its own stack', '`pages/shopping_cart/`'],
          [
            'Contacts',
            'List → `/contacts/:id` → `edit`, `onExit` confirmation dialog with `useRootNavigator` chosen via `AdaptivePaneScope`',
            '`pages/contacts/`',
          ],
          ['Mine', 'Nested `theme` / `account` pages, `about` as a `fullscreenDialog`', '`pages/mine/`'],
          [
            'Shell',
            'Compact `NavigationBar` inside `AdaptiveShellChrome` vs `NavigationRail`, re-tapping a tab with `goBranch(i, initialLocation: true)`, `PopScope` exit confirmation',
            '`shell/app_shell.dart`',
          ],
          [
            'Router',
            'The complete route table, breadcrumbs, custom resize handle and card panes',
            '`router/router_pages.dart`',
          ],
        ],
      ),
      DocHeading('run', 'Run it'),
      DocCode(CodeLanguage.shell, '''
cd example && flutter run -d chrome
cd example && flutter test'''),
    ],
  ),
  DocId.migrating2x => const DocPage(
    id: DocId.migrating2x,
    title: 'Migrating from 2.x',
    description: 'Map the 2.x SlidingShell APIs to the 3.x route table.',
    blocks: [
      DocTable(
        ['2.x', '3.x'],
        [
          [
            '`SlidingShell` + per-tab `MultiColumnScaffold` + `AdaptiveNavigator` + 9-method fallback',
            'one `AdaptiveRouter` + `MaterialApp.router`',
          ],
          ['`handlesRoute` / `buildPage` / `resolveTitle`', '`AdaptiveRoute` in the table'],
          ['`from:` / `openAfter` / `openSecondary`', 'URL is the stack (`pushNamed` prefix vs append)'],
          ['`extra`', '`arguments`'],
          ['`inSlidingWindow(context)`', '`AdaptivePaneScope.maybeOf(context) != null`'],
          ['`SlidingPageTitle.report`', '`AdaptivePaneScope.maybeOf(context)?.title.value = …`'],
          ['`SlidingActions.pop`', '`AdaptiveRouter.of(context).maybePop()`'],
        ],
      ),
      DocCallout(CalloutKind.warning, 'There is no compatibility shim. See the CHANGELOG for every breaking change.'),
    ],
  ),
  DocId.migratingGoRouter => const DocPage(
    id: DocId.migratingGoRouter,
    title: 'Migrating from go_router',
    description: 'Equivalent concepts and calls for go_router users.',
    blocks: [
      DocTable(
        ['go_router', 'this package'],
        [
          ['`GoRoute`', '`AdaptiveRoute`'],
          ['`StatefulShellRoute.indexedStack`', '`AdaptiveShellRoute` + `AdaptiveBranch`'],
          ['`context.go(loc)`', '`router.pushNamedAndRemoveUntil(loc, (_) => false)`'],
          ['`context.push(loc)`', '`router.pushNamed(loc)`'],
          ['`extra`', '`arguments`'],
          ['`GoRouterState`', '`AdaptiveRouteState`'],
          ['`pageBuilder`', '`builder` + optional `transitionsBuilder`'],
          ['`context.go` / `context.pop` extensions', '`AdaptiveRouter.of(context)` only'],
        ],
      ),
    ],
  ),
  DocId.caveats => const DocPage(
    id: DocId.caveats,
    title: 'Caveats',
    description: 'Known limits around breakpoints, overlays, pop semantics and the web.',
    blocks: [
      DocHeading('breakpoint-rebuild', 'Crossing the breakpoint rebuilds state'),
      DocParagraph(
        'Crossing the 840 breakpoint **rebuilds** page `State` (Navigator tree ↔ viewport tree). Keep durable state in the route URL, a signal, or a host store.',
      ),
      DocHeading('overlays', 'Pane overlays are clipped'),
      DocParagraph(
        'Dialogs, menus, and sheets inside a column should use the root overlay: `useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`. On compact, a tab-root sheet stays on the nearest navigator and covers the bottom bar only when the shell uses `AdaptiveShellChrome`.',
      ),
      DocHeading('context-free-pop', 'Context-free pop'),
      DocParagraph(
        'Context-free `pop` / `maybePop` (including Escape and system back) only handle the top pane and root / shell popups that cover everything. A pane-local sheet / dialog in the **other** pane is not closed by them: use `maybePopFrom(context)`, or `Navigator.pop(context)` from inside the popup. Stacked popups close outermost first (root → shell → pane).',
      ),
      DocHeading('on-exit', 'When onExit runs'),
      DocParagraph(
        '`onExit` runs for `maybePop`, system back, and browser back, after the top page\'s `PopScope`. At the bottom of the stack, system back asks the route\'s `onExit` before the app exits. `pop` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` run immediately, like `Navigator`.',
      ),
      DocHeading('web', 'Web'),
      DocParagraph(
        'Web keeps hash URLs. The platform\'s initial route wins over `initialLocation` when it is not `/`.',
      ),
      DocHeading('limits', 'Scope limits'),
      DocCallout(
        CalloutKind.danger,
        'One `AdaptiveShellRoute`, top-level only. No nested shells, no `restorable*`, no `context.pushNamed` extensions.',
      ),
    ],
  ),
  DocId.packageSkills => const DocPage(
    id: DocId.packageSkills,
    title: 'Package Skills',
    description: 'Install the agent skills shipped with the package so coding agents use the real APIs.',
    blocks: [
      DocParagraph(
        'This package ships [agent skills](https://dart.dev/tools/pub/package-skills) under `skills/`. After you depend on it, install them so coding agents use the real APIs:',
      ),
      DocCode(CodeLanguage.shell, 'dart run skills@ get -p xue_hua_adaptive_sliding_layout --all'),
      DocHeading('skills', 'Skills'),
      DocTable(
        ['Skill', 'When'],
        [
          ['`xue-hua-adaptive-sliding-layout-setup`', '`AdaptiveRouter` + `MaterialApp.router`'],
          ['`xue-hua-adaptive-sliding-layout-routing`', 'Route table, `:param`, `redirect`, `onExit`'],
          ['`xue-hua-adaptive-sliding-layout-navigation`', '`pushNamed` / `pop` / `goBranch`'],
          ['`xue-hua-adaptive-sliding-layout-layout`', 'Panes, breakpoints, breadcrumbs'],
        ],
      ),
    ],
  ),
};
