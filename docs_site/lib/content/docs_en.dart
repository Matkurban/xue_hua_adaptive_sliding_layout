// Documentation content for xue_hua_adaptive_sliding_layout (English).
// Source of truth: the package README, CHANGELOG, lib/ and example/lib.
//
// The pages form a progressive tutorial: each one starts from the previous
// page's complete `lib/main.dart` (see tutorial_code.dart) and adds one idea.
import '../models/doc_id.dart';
import '../models/doc_page.dart';
import 'tutorial_code.dart';

DocPage page(DocId id) => switch (id) {
  DocId.introduction => const DocPage(
    id: DocId.introduction,
    title: 'Introduction',
    description: 'What xue_hua_adaptive_sliding_layout solves, and how one route table becomes one or two columns.',
    blocks: [
      DocParagraph(
        'Phone apps push pages full-screen. Desktop and tablet apps show a **list and its detail side by side**. Building both usually means two navigation systems that drift apart.',
      ),
      DocParagraph(
        '`xue_hua_adaptive_sliding_layout` gives you **one route table**. A URL becomes a stack of pages, and the window width decides how that stack is shown:',
      ),
      DocLayoutDiagram(
        compactLabel: 'Narrow window (< 840): one column',
        expandedLabel: 'Wide window (≥ 840): two sliding columns',
        listLabel: 'Products',
        detailLabel: 'Coffee mug',
        caption:
            'Same URL `/products/1`, same stack `[Products, Coffee mug]`. Narrow: a normal `Navigator` shows the top page. Wide: the last two pages sit side by side, with breadcrumbs and a resize handle.',
      ),
      DocHeading('how', 'How it works in one line'),
      DocCode(CodeLanguage.plain, '''
URL /products/1/reviews
  → match the route table  → stack [products, 1, reviews]
  → window width < 840     → 1 column: Navigator shows "reviews"
  → window width ≥ 840     → 2 columns: "1" | "reviews" ("products" slid off to the left)'''),
      DocParagraph(
        'You navigate with the verbs you already know from `Navigator` — `pushNamed`, `pop`, `maybePop`… — called on `AdaptiveRouter.of(context)`. Back buttons, system back, browser back, deep links and refresh all go through the same URL, so the stack is always consistent.',
      ),
      DocHeading('tutorial', 'What you will build'),
      DocParagraph(
        'The tutorial builds one small shop app, a step at a time. Every step gives you a complete `lib/main.dart` to paste:',
      ),
      DocList([
        '[First app](doc:first-app): one route, `MaterialApp.router`.',
        '[Nested routes](doc:nested-routes): a product list and `/products/:id` detail.',
        '[Navigation](doc:navigation): push, pop, return a result, replace, reset.',
        '[Tabs](doc:tabs): a Products tab and an Account tab with their own stacks.',
        '[Two columns](doc:two-columns): what happens at 840 px, placeholders, the resize handle.',
        '[Titles & breadcrumbs](doc:titles-and-breadcrumbs), then [redirects, sign-in and onExit](doc:redirects-and-on-exit).',
        'Finally [customizing the UI](doc:customizing-ui), [reading state](doc:reading-state) and [using the layout without the router](doc:layout-without-router).',
      ], ordered: true),
      DocCallout(
        CalloutKind.tip,
        'Want to see the end result first? Open the [live demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/) and use its width presets (phone / tablet / desktop) to watch the same screens switch between one and two columns.',
      ),
      DocParagraph('**Next:** [Installation](doc:installation).'),
    ],
  ),
  DocId.installation => const DocPage(
    id: DocId.installation,
    title: 'Installation',
    description: 'SDK requirements and the three dependencies the tutorial uses.',
    blocks: [
      DocCallout(CalloutKind.info, 'Add the package to a Flutter app and check the imports compile.', title: 'Goal'),
      DocHeading('requirements', 'Requirements'),
      DocTable(
        ['Item', 'Constraint'],
        [
          ['Flutter', '`>=3.47.0`'],
          ['Dart SDK', '`^3.13.0`'],
          ['Pulled in by the package', '`signals_flutter: ^7.1.0`, `material_ui: ^1.6.0`'],
        ],
      ),
      DocHeading('add', 'Add the dependencies'),
      DocParagraph(
        'Create an app (or use an existing one) and add the package. The tutorial code also imports `material_ui` (Material widgets, as in the package example) and `signals_flutter` (for a little app state later), so add them directly too:',
      ),
      DocCode(CodeLanguage.shell, '''
flutter create shop
cd shop
flutter pub add xue_hua_adaptive_sliding_layout material_ui signals_flutter'''),
      DocParagraph('Your `pubspec.yaml` now contains:'),
      DocCode(CodeLanguage.yaml, '''
dependencies:
  flutter:
    sdk: flutter
  xue_hua_adaptive_sliding_layout: ^3.4.3
  material_ui: ^1.6.0
  signals_flutter: ^7.1.0''', fileName: 'pubspec.yaml'),
      DocHeading('imports', 'Imports'),
      DocParagraph('Every tutorial file starts with these two imports:'),
      DocCode(CodeLanguage.dart, '''
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';'''),
      DocCallout(
        CalloutKind.tip,
        'Using a coding agent? The package ships agent skills that teach it the real APIs — see [AI: Skills](doc:skills).',
      ),
      DocParagraph('**Next:** [Your first app](doc:first-app).'),
    ],
  ),
  DocId.firstApp => const DocPage(
    id: DocId.firstApp,
    title: 'Your First App',
    description: 'The smallest runnable app: one route in an AdaptiveRouter, handed to MaterialApp.router.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Run an app whose single page comes from an `AdaptiveRouter` route table.',
        title: 'Goal',
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph('Replace `lib/main.dart` with:'),
      DocCode(CodeLanguage.dart, firstAppMain, fileName: 'lib/main.dart'),
      DocHeading('explained', 'What each part does'),
      DocList([
        '**`AdaptiveRouter`** is the route table. You create it once and keep it in a top-level variable (or any object your app owns) — there is no service locator. `initialLocation` is where the app starts when the platform gives no URL.',
        '**`AdaptiveRoute`** is one page: a `path` and a `builder(context, state)` that returns an ordinary widget.',
        '**`MaterialApp.router(routerConfig: router)`** plugs the router into Flutter. `AdaptiveRouter` is a `RouterConfig`, so nothing else is needed.',
        '**`ProductsPage`** is a plain `Scaffold`. Pages do not extend or know about anything from the package.',
      ], ordered: true),
      DocHeading('run', 'Run it'),
      DocCode(CodeLanguage.shell, 'flutter run -d chrome'),
      DocParagraph(
        'You will see one page titled **Products** saying “Hello from /products”. On the web the address bar shows `/#/products`: the router uses hash URLs, so the app can be hosted on any static server (GitHub Pages included) without rewrite rules.',
      ),
      DocCallout(
        CalloutKind.tip,
        'One page is not very adaptive yet. The interesting part starts when there is a **stack** of pages — that is the next step.',
      ),
      DocParagraph('**Next:** [Nested routes & parameters](doc:nested-routes).'),
    ],
  ),
  DocId.nestedRoutes => const DocPage(
    id: DocId.nestedRoutes,
    title: 'Nested Routes & Parameters',
    description: 'Add a product detail page at /products/:id and read path and query parameters.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Tap a product in a list to open `/products/:id`, and understand why the list stays underneath.',
        title: 'Goal',
      ),
      DocHeading('rules', 'Three path rules'),
      DocList([
        '**Child paths are relative** to their parent: a child `:id` under `/products` matches `/products/1`.',
        '**`:param` matches exactly one path segment.** Its value arrives in `state.pathParameters`.',
        '**First match wins**, in the order you declare routes.',
      ]),
      DocParagraph(
        'Matching `/products/2` walks the tree and collects every route on the way: `[products, 2]`. **That list is the page stack.** So a deep link to a detail page still has the list beneath it, and back goes to the list.',
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph(
        'Compared to the previous step: a small `Product` model, a child route `:id`, a list that calls `pushNamed`, and a detail page.',
      ),
      DocCode(CodeLanguage.dart, nestedRoutesMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'The list shows three products. Tapping one pushes its detail page; the AppBar back arrow returns to the list.',
        'Open `/#/products/2?ref=mail` directly in the browser: the detail opens with `ref: mail`, and back still leads to the list, because the URL produced the stack `[products, 2]`.',
        'Open `/#/products/99`: the route matches, `findProduct` returns null and the page says so. (URLs that match **no** route go to the router\'s `errorBuilder`, covered in [Redirects](doc:redirects-and-on-exit).)',
      ]),
      DocHeading('state', 'Where parameters come from'),
      DocParagraph(
        'The builder receives an `AdaptiveRouteState`; inside the page you can also call `AdaptiveRouteState.of(context)`. Useful fields: `pathParameters`, `queryParameters`, `uri`, `arguments`, `name`.',
      ),
      DocCallout(
        CalloutKind.info,
        'The detail page sets `leading: BackButton(onPressed: () => AdaptiveRouter.of(context).maybePop())`, exactly like the package example. `maybePop` is the polite back: it is what system back, browser back and Escape call too. The next page explains it.',
      ),
      DocParagraph('**Next:** [Navigating between pages](doc:navigation).'),
    ],
  ),
  DocId.navigation => const DocPage(
    id: DocId.navigation,
    title: 'Navigating Between Pages',
    description: 'pushNamed and pop first, then results, named locations, replacing and resetting the stack.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Use the Navigator-style verbs on `AdaptiveRouter.of(context)`: rate a product and get the rating back, jump to the next product, and reset to the list.',
        title: 'Goal',
      ),
      DocHeading('basics', 'The two you already used'),
      DocList([
        '`pushNamed(location)` adds a page. The argument is a **location** (a path), not a route name.',
        '`pop([result])` removes the top page immediately. `maybePop()` asks first (the page\'s `PopScope`, then the route\'s `onExit`) — use it for back buttons.',
      ]),
      DocParagraph(
        'There is no `push(Route)`: every page must be in the route table so the URL can always describe the stack.',
      ),
      DocHeading('more', 'Three more verbs, one at a time'),
      DocTable(
        ['Verb', 'In this step'],
        [
          [
            '`await pushNamed<int>(...)` + `pop(stars)`',
            'The detail page opens `/products/:id/reviews` and waits; the reviews page calls `pop(4)`; the `Future` completes with `4`.',
          ],
          [
            '`namedLocation(name, pathParameters:)`',
            'Builds `/products/2` from the route named `product`, so paths are not glued together by hand.',
          ],
          [
            '`pushReplacementNamed(location)`',
            '“Next product” swaps the top page. Back still goes to the list, not to the previous product.',
          ],
          [
            '`pushNamedAndRemoveUntil(location, (_) => false)`',
            '“Back to the list” rebuilds the whole stack from a URL — the same call you will use after sign-in and for deep links.',
          ],
        ],
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph(
        'The route `:id` gets a `name` and a child `reviews`; the detail page gets three buttons; a `ReviewsPage` is added.',
      ),
      DocCode(CodeLanguage.dart, navigationMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'Detail → **Rate this product** → pick “4 stars”: you are back on the detail and the button reads “Your rating: 4 stars”.',
        '**Next: Notebook** replaces the page: the URL changes to `/#/products/2`, and back returns to the list.',
        '**Back to the list** clears everything above `/products`.',
      ]),
      DocCallout(
        CalloutKind.tip,
        'The full list — including `popAndPushNamed`, `popUntil`, `canPop`, `popFrom` and `maybePopFrom` — is in [Navigation verbs](doc:navigation-verbs). You will not need them for this tutorial.',
      ),
      DocParagraph('**Next:** [Adding tabs](doc:tabs).'),
    ],
  ),
  DocId.tabs => const DocPage(
    id: DocId.tabs,
    title: 'Adding Tabs',
    description: 'Wrap the routes in an AdaptiveShellRoute with one AdaptiveBranch per tab.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Add a Products tab and an Account tab. Each tab keeps its own stack; the bar is a bottom `NavigationBar` on phones and a `NavigationRail` on wider windows.',
        title: 'Goal',
      ),
      DocHeading('concepts', 'Three new types'),
      DocTable(
        ['Type', 'What it is'],
        [
          [
            '`AdaptiveShellRoute`',
            'The app chrome around the tabs. **One per app, top-level only.** Its `builder(context, shell, child)` returns your chrome with `child` (the current tab) inside. It is also what enables the two-column layout.',
          ],
          ['`AdaptiveBranch`', 'One tab: a list of `routes` with its own page stack.'],
          [
            '`AdaptiveShellState`',
            'The `shell` argument: `currentIndex`, `goBranch(index)`, and the width band — `isCompact`, `isMedium`, `isExpanded`.',
          ],
        ],
      ),
      DocParagraph(
        'On compact widths wrap the tab in **`AdaptiveShellChrome`** and pass the bar as a builder. The bar then lives inside the tab page, so pushed pages (and bottom sheets) can cover it.',
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph(
        'The `/products` route moves, unchanged, into the first branch. A second branch holds `/account`. A new `AppShell` widget draws the bar.',
      ),
      DocCode(CodeLanguage.dart, tabsMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'Phone width: a bottom bar. Open a product, switch to **Account**, switch back — the product is still open. Each branch remembers its stack.',
        'Tap **Products** again while on it: `goBranch(index, initialLocation: true)` returns that tab to its first page.',
        'On a phone the bottom bar hides on pages pushed above the tab root (`AdaptiveRoute.hidesBottomBarWhenPushed`, default `true`).',
        'Make the window wider than 600 px: the rail replaces the bar.',
        'Wider than 840 px and open a product… the list and the detail appear **side by side**. You did not write anything for that — the next page explains it.',
      ]),
      DocCallout(
        CalloutKind.warning,
        'Don\'t also set `Scaffold.bottomNavigationBar` when you use `AdaptiveShellChrome` — one bottom bar is enough.',
      ),
      DocParagraph('**Next:** [Two columns & breakpoints](doc:two-columns).'),
    ],
  ),
  DocId.twoColumns => const DocPage(
    id: DocId.twoColumns,
    title: 'Two Columns & Breakpoints',
    description: 'What happens at 840 px, how pages slide, the empty right column and the resize handle.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Understand the two-column mode you got in the previous step, and set a placeholder for the empty right column.',
        title: 'Goal',
      ),
      DocHeading('bands', 'Width bands'),
      DocParagraph('Breakpoints use the **window width**, not the device type:'),
      DocTable(
        ['Window width', 'Band', 'What the shell shows'],
        [
          ['< 600 (`compactMaxWidth`)', 'compact', 'One column: a classic `Navigator`'],
          ['600 – 839', 'medium', 'Still one column; your chrome can react via `shell.isMedium`'],
          ['≥ 840 (`expandedMinWidth`)', 'expanded', 'Two columns: the **last two pages** of the stack'],
        ],
      ),
      DocHeading('sliding', 'How pages move'),
      DocList([
        'Stack `[products]`: list on the left, the **placeholder** on the right.',
        '`pushNamed(\'/products/1\')` → `[products, 1]`: the detail fills the right column.',
        'Push `reviews` → `[products, 1, reviews]`: everything slides one column left; the detail is now on the left, reviews on the right.',
        'Back slides them back. Drag the handle between the columns to resize them (left starts at 40%, each side keeps at least 35%).',
      ], ordered: true),
      DocHeading('code', 'The complete file'),
      DocParagraph(
        'Only the `AdaptiveShellRoute` changes: an explicit `breakpoints` (840 is the default — write it when you want another value) and a `placeholder`.',
      ),
      DocCode(CodeLanguage.dart, twoColumnsMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'At 1200 px: products on the left, “Pick a product” on the right. Tap a product: it opens on the right, the list stays visible.',
        'Rate it: the detail slides to the left and the rating page appears on the right.',
        'Narrow the window below 840 px: the same stack is shown as one column, top page only. Widen it again: two columns.',
        'A placeholder per tab is possible too: `AdaptiveBranch(placeholder: ...)` wins over the shell-level one.',
      ]),
      DocCallout(
        CalloutKind.warning,
        'Crossing 840 **rebuilds** page `State` (the Navigator tree and the column tree are different widget trees). Keep anything you must not lose in the URL, a signal, or a store — not only in a `State` field.',
      ),
      DocParagraph('**Next:** [Titles & breadcrumbs](doc:titles-and-breadcrumbs).'),
    ],
  ),
  DocId.titlesBreadcrumbs => const DocPage(
    id: DocId.titlesBreadcrumbs,
    title: 'Titles & Breadcrumbs',
    description: 'Give routes titles so the breadcrumb strip above the two columns can show where you are.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Show “Products › Coffee mug › Rate” above the columns, and jump back by tapping a crumb.',
        title: 'Goal',
      ),
      DocHeading('title', 'Route titles'),
      DocParagraph(
        '`AdaptiveRoute.title` is a `String Function(AdaptiveRouteState state)`. It runs **once, when the route is matched**, and has no `BuildContext` — derive the title from `state.pathParameters` or `state.uri`.',
      ),
      DocParagraph(
        'In two-column mode the shell draws `AdaptiveBreadcrumbs` above the columns (`showBreadcrumbs: true` is the default). Tapping an earlier crumb pops back to it.',
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph('Every route gets a `title`; the detail title is looked up from the id.'),
      DocCode(CodeLanguage.dart, titlesMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'Wide window, open Coffee mug and then Rate: the strip reads **Products › Coffee mug › Rate**.',
        'Tap **Products** in the strip: you are back on the list.',
        'Below 840 px there is no strip — the AppBar title is enough in one column.',
      ]),
      DocHeading('async', 'Titles that arrive later'),
      DocParagraph(
        'If the title is only known after loading (or needs `BuildContext`, e.g. for localization), set it from the page. `AdaptivePaneScope.maybeOf(context)` is non-null only inside a column:',
      ),
      DocCode(CodeLanguage.dart, '''
// e.g. in didChangeDependencies or after your data loads:
AdaptivePaneScope.maybeOf(context)?.title.value = product.name;'''),
      DocList([
        'A static `title` is not re-evaluated when the locale changes; use the page-side assignment if titles must follow a live language switch.',
        'For context-free localization inside `title`, use gen-l10n\'s `lookupAppLocalizations(locale)` or `Intl.defaultLocale`.',
        'Restyle the strip with `breadcrumbsBuilder` (see [Customizing the UI](doc:customizing-ui)) or hide it with `showBreadcrumbs: false`.',
      ]),
      DocParagraph('**Next:** [Redirects, sign-in & onExit](doc:redirects-and-on-exit).'),
    ],
  ),
  DocId.redirectsOnExit => const DocPage(
    id: DocId.redirectsOnExit,
    title: 'Redirects, Sign-in & onExit',
    description:
        'Guard a page behind sign-in with redirect, return the user afterwards, and confirm before leaving unsaved edits.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Make `/account/profile` require sign-in, send the user back there after signing in, and ask “Discard changes?” when leaving an edited profile.',
        title: 'Goal',
      ),
      DocHeading('redirect', 'redirect'),
      DocList([
        '`AdaptiveRouter.redirect` runs before every navigation; `AdaptiveRoute.redirect` runs for one route. Both are `(context, state) => FutureOr<String?>`: return a location to go there instead, or `null` to continue.',
        'Redirect chains stop after `redirectLimit` (5) and show `errorBuilder` — the same page used for URLs that match no route.',
        'After your auth state changes, call `router.refresh()` to re-run redirects for the current location.',
      ]),
      DocHeading('fullscreen', 'A full-screen login route'),
      DocParagraph(
        'Routes declared **outside** the shell (or with `fullscreen: true`) are shown on the root `Navigator`, covering the tabs at every width — right for login, splash or onboarding.',
      ),
      DocHeading('on-exit', 'onExit'),
      DocParagraph(
        '`AdaptiveRoute.onExit` is asked before the page is left by `maybePop`, the back button, system back or browser back. Return `false` to stay. `pop`, `pushReplacementNamed` and `pushNamedAndRemoveUntil` do **not** ask — like `Navigator`.',
      ),
      DocParagraph(
        'Inside a column, show the dialog on the root navigator so it is not clipped to the column: `useRootNavigator: AdaptivePaneScope.maybeOf(context) != null`.',
      ),
      DocHeading('code', 'The complete file'),
      DocParagraph(
        'New: two signals for app state, a top-level `redirect`, a `/login` route outside the shell, and a `profile` child route with `onExit`.',
      ),
      DocCode(CodeLanguage.dart, redirectsMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'Account → **Edit profile** while signed out: the URL becomes `/#/login?from=%2Faccount%2Fprofile` and the login page covers everything.',
        '**Sign in**: `pushNamedAndRemoveUntil(from, (_) => false)` rebuilds the stack `[account, profile]`.',
        'Type in the field, then press back: “Discard changes?”. **Stay** keeps you on the page; **Discard** leaves.',
        '**Sign out** + `refresh()`: the guard applies again on the next visit.',
      ]),
      DocParagraph(
        'This is how the package example guards its account page — compare with `example/lib/router/router_pages.dart`.',
      ),
      DocParagraph('**Next:** [Customizing the UI](doc:customizing-ui).'),
    ],
  ),
  DocId.customizingUi => const DocPage(
    id: DocId.customizingUi,
    title: 'Customizing the UI',
    description: 'Restyle the columns, resize handle and breadcrumbs, and add overlay routes such as a photo viewer.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Give the tutorial app card-style columns, a custom resize handle and breadcrumb strip, and learn the overlay-route options.',
        title: 'Goal',
      ),
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
      DocHeading('apply', 'Apply it to the tutorial app'),
      DocParagraph(
        'Start from the previous step\'s `lib/main.dart` and give its `AdaptiveShellRoute` these arguments (keep `branches` as they are). Every value here is a real parameter; the code is checked with `flutter analyze`.',
      ),
      DocCode(CodeLanguage.dart, r'''
AdaptiveShellRoute(
  breakpoints: const LayoutBreakpoints(expandedMinWidth: 840),
  showBreadcrumbs: true,
  resizable: true,
  initialLeftPaneFraction: 0.4,
  placeholder: (context) => const Center(child: Text('Pick a product')),
  slideDuration: const Duration(milliseconds: 280),
  resizeHandleBuilder: (context, isHovered) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: KeyedSubtree(key: const Key('pane-flat'), child: child),
    );
  },
  builder: (context, shell, child) => AppShell(shell: shell, child: child),
  branches: [/* unchanged */],
)'''),
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
      DocCode(CodeLanguage.dart, r'''
// Add as a child of the ':id' route, next to 'reviews'.
AdaptiveRoute(
  path: 'photo',
  title: (_) => 'Photo',
  fullscreen: true,
  opaque: false,
  barrierColor: Colors.black,
  barrierDismissible: true,
  transitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
  builder: (context, state) => const Center(child: Icon(Icons.image, size: 200)),
)'''),
      DocParagraph(
        'Open it from the detail page with `router.pushNamed(\'/products/1/photo\')`. It covers the whole window at every width with a fade; tap the black barrier to close it.',
      ),
      DocParagraph('**Next:** [Reading state](doc:reading-state).'),
    ],
  ),
  DocId.readingState => const DocPage(
    id: DocId.readingState,
    title: 'Reading State',
    description: 'Read the current location, route parameters, pane and shell scopes from any widget.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Know where you are from any widget: the location, parameters, whether you are in a column, and the shell\'s width band.',
        title: 'Goal',
      ),
      DocHeading('cheatsheet', 'Cheat sheet'),
      DocCode(CodeLanguage.dart, '''
AdaptiveRouter.of(context).location.value;               // '/products/1'
AdaptiveRouteState.of(context).pathParameters;           // {'id': '1'}
AdaptivePaneScope.maybeOf(context) != null;              // inside a two-column pane?
AdaptivePaneScope.maybeOf(context)?.title.value = name;  // breadcrumb title
AdaptiveShellScope.maybeOf(context)?.isExpanded;         // two columns right now?'''),
      DocHeading('live', 'A live location label'),
      DocParagraph(
        '`location`, `matches` and `currentBranch` on the router are signals. Wrap readers in `SignalBuilder` (from `signals_flutter`) and they rebuild on every navigation. Drop this into the tutorial\'s `AccountPage` list:',
      ),
      DocCode(CodeLanguage.dart, '''
SignalBuilder(
  builder: (context) => ListTile(
    leading: const Icon(Icons.link),
    title: Text(AdaptiveRouter.of(context).location.value),
  ),
)'''),
      DocHeading('scopes', 'Pane and shell scopes'),
      DocList([
        '`AdaptivePaneScope.maybeOf(context)` is non-null only inside a two-column pane. Use it to choose `useRootNavigator` for dialogs and to set titles.',
        '`AdaptiveShellScope.maybeOf(context)` gives the `AdaptiveShellState` (`currentIndex`, `isCompact`, `isMedium`, `isExpanded`, `goBranch`) to widgets deep inside the shell.',
      ]),
      DocHeading('chrome', 'Drawing titles in your own chrome'),
      DocParagraph(
        'To render titles somewhere other than the built-in breadcrumb strip, read `AdaptiveRouter.of(context).matches.value.branchMatches`; each match has a `title` signal and a `name`.',
      ),
      DocParagraph('**Next:** [Layout without the router](doc:layout-without-router).'),
    ],
  ),
  DocId.layoutWithoutRouter => const DocPage(
    id: DocId.layoutWithoutRouter,
    title: 'Layout Without the Router',
    description:
        'Use SlidingPaneViewport, SlidingPane and AdaptiveBreadcrumbs directly when you only want the sliding columns.',
    blocks: [
      DocCallout(
        CalloutKind.info,
        'Build a folder browser with sliding columns from your own list of pages — no routes, no URLs.',
        title: 'Goal',
      ),
      DocParagraph(
        'The shell uses public widgets you can use on their own, e.g. inside one screen of an app that already has another router. You own the stack (a `List`) and rebuild when it changes.',
      ),
      DocHeading('code', 'The complete file'),
      DocCode(CodeLanguage.dart, layoutWithoutRouterMain, fileName: 'lib/main.dart'),
      DocHeading('see', 'What you will see'),
      DocList([
        'Wide window: “Home” on the left, “Open a folder” on the right. Open folders and the columns slide like in the router version.',
        'Tap a breadcrumb to cut the stack back; drag the handle to resize.',
        'Narrow window: `visibleColumnCount` returns 1 and only the top folder is shown; the AppBar back arrow calls `onPop`.',
      ]),
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
      DocParagraph('That completes the tutorial. **Next:** the [Route table reference](doc:route-table).'),
    ],
  ),
  DocId.routeTable => const DocPage(
    id: DocId.routeTable,
    title: 'Route Table',
    description:
        'Reference for AdaptiveRouter, AdaptiveRoute, AdaptiveShellRoute, AdaptiveBranch and the state objects.',
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
    description:
        'Every verb on AdaptiveRouter, how it behaves in one and two columns, tab switching and exit confirmation.',
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
  DocId.exampleApp => const DocPage(
    id: DocId.exampleApp,
    title: 'Example App Walkthrough',
    description: 'How the bundled example app is organised, in the order worth reading it.',
    blocks: [
      DocParagraph(
        'The `example/` app is the integration template: everything from the tutorial, at full size. On the [live demo](https://matkurban.github.io/xue_hua_adaptive_sliding_layout/example/) the top bar pins phone / foldable / tablet / desktop widths, so you can see every breakpoint without resizing the window.',
      ),
      DocHeading('run', 'Run it'),
      DocCode(CodeLanguage.shell, '''
cd example
flutter run -d chrome
flutter test'''),
      DocHeading('order', 'Reading order'),
      DocList([
        '`lib/main.dart` — `MaterialApp.router(routerConfig: RouterPages.router)` plus the width-preset wrapper (`pages/size_preset_screen.dart`).',
        '`lib/router/router_names.dart` — every path and route name as a constant.',
        '`lib/router/router_pages.dart` — the complete route table: top-level `redirect`, auth routes outside the shell, the `AdaptiveShellRoute` with its custom handle, breadcrumbs and card panes, and the branches.',
        '`lib/shell/app_shell.dart` — `AdaptiveShellChrome` + `NavigationBar` vs `NavigationRail`, re-tapping a tab, and `PopScope` exit confirmation.',
        '`lib/pages/…` — the screens, one folder per area (table below). `lib/services/` holds the signals they share.',
      ], ordered: true),
      DocHeading('areas', 'Areas'),
      DocTable(
        ['Area', 'What it shows', 'Tutorial step', 'Files'],
        [
          [
            'Auth',
            'Full-screen splash / login / register; `redirect` to `/login?from=` for the account page',
            '[Redirects](doc:redirects-and-on-exit)',
            '`pages/auth/`',
          ],
          [
            'Home',
            'Product list → `/home/:id` with a `title` from the id; translucent full-screen image preview via `transitionsBuilder`',
            '[Nested routes](doc:nested-routes), [Customizing](doc:customizing-ui)',
            '`pages/home/`',
          ],
          ['Shopping cart', 'A separate branch with its own stack', '[Tabs](doc:tabs)', '`pages/shopping_cart/`'],
          [
            'Contacts',
            'List → `/contacts/:id` → `edit`; `onExit` dialog with `useRootNavigator` chosen via `AdaptivePaneScope`',
            '[onExit](doc:redirects-and-on-exit)',
            '`pages/contacts/`',
          ],
          [
            'Mine',
            'Nested `theme` / `account` pages; `about` as a `fullscreenDialog`',
            '[Customizing](doc:customizing-ui)',
            '`pages/mine/`',
          ],
          [
            'Shell',
            'Bar vs rail, `goBranch(i, initialLocation: true)`, `PopScope` exit confirmation',
            '[Tabs](doc:tabs)',
            '`shell/app_shell.dart`',
          ],
        ],
      ),
      DocHeading('try', 'Things to try in the demo'),
      DocList([
        'Desktop preset → Contacts → a contact → edit: three levels, two columns, breadcrumbs.',
        'Type in the remark, press Escape: the `onExit` dialog.',
        'Mine → account while signed out: redirected to login, then returned.',
        'Switch between the phone and desktop presets with a detail page open.',
      ]),
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
  DocId.skills => const DocPage(
    id: DocId.skills,
    title: 'Skills',
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
