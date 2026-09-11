import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo_pages.dart';

void main() {
  ensureDemoReady();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    ensureDemoReady();
    return MaterialApp(
      navigatorKey: demoNavKey,
      title: 'Adaptive Sliding Layout',
      home: const DemoShellPage(),
    );
  }
}

class DemoShellPage extends StatelessWidget {
  const DemoShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        demoShell.updateViewportWidth(width);
        final compact = LayoutBreakpoints.isCompact(width);
        return SignalBuilder(
          builder: (context) {
            final viewportWidth = demoShell.viewportWidth.value;
            final visibleCount = LayoutBreakpoints.visibleColumnCount(
              viewportWidth,
            );
            final showBreadcrumbs = LayoutBreakpoints.isExpanded(viewportWidth);
            final stack = IndexedStack(
              index: demoShell.currentIndex.value,
              children: [
                _DemoTabScaffold(
                  controller: demoShell.stacks[0],
                  root: const HomeTab(),
                  rootName: 'Home',
                  visibleCount: visibleCount,
                  showBreadcrumbs: showBreadcrumbs,
                ),
                _DemoTabScaffold(
                  controller: demoShell.stacks[1],
                  root: const ExploreTab(),
                  rootName: 'Explore',
                  visibleCount: visibleCount,
                  showBreadcrumbs: showBreadcrumbs,
                ),
              ],
            );
            return Scaffold(
              body: compact
                  ? stack
                  : Row(
                      children: [
                        NavigationRail(
                          key: DemoKeys.navRail,
                          selectedIndex: demoShell.currentIndex.value,
                          onDestinationSelected: demoShell.changePage,
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home_outlined),
                              label: Text('Home'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.explore_outlined),
                              label: Text('Explore'),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: stack),
                      ],
                    ),
              bottomNavigationBar: compact
                  ? NavigationBar(
                      key: DemoKeys.navBar,
                      selectedIndex: demoShell.currentIndex.value,
                      onDestinationSelected: demoShell.changePage,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.explore_outlined),
                          label: 'Explore',
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

/// Subscribes only to [SlidingShell.leftPaneFraction] so a drag does not rebuild the rail.
class _DemoTabScaffold extends StatelessWidget {
  const _DemoTabScaffold({
    required this.controller,
    required this.root,
    required this.rootName,
    required this.visibleCount,
    required this.showBreadcrumbs,
  });

  final SlidingWindowController controller;
  final Widget root;
  final String rootName;
  final int visibleCount;
  final bool showBreadcrumbs;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        return MultiColumnScaffold(
          controller: controller,
          root: root,
          rootName: rootName,
          visibleCount: visibleCount,
          showBreadcrumbs: showBreadcrumbs,
          onEscapePop: demoNavigator.pop,
          leftPaneFraction: demoShell.leftPaneFraction.value,
          onLeftPaneFractionChanged: (value) =>
              demoShell.leftPaneFraction.value = value,
        );
      },
    );
  }
}
