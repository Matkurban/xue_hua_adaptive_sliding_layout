import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingPaneViewport keep-alive', () {
    setUp(() {
      _KeepAliveProbe.initCount = 0;
    });

    testWidgets('depth 2 to 3 keeps the previous right pane State', (
      tester,
    ) async {
      final root = _pane('Root');
      final a = _pane('A', child: const _KeepAliveProbe(label: 'A'));
      await tester.pumpWidget(_KeepAliveHarness(panes: [root, a]));
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      await tester.pumpWidget(
        _KeepAliveHarness(
          panes: [
            root,
            a,
            _pane('B', child: const ColoredBox(color: Colors.green)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);
      expect(find.text('probe-A'), findsOneWidget);
    });

    testWidgets('depth 1 to 2 keeps the root pane State', (tester) async {
      final root = _pane('Root', child: const _KeepAliveProbe(label: 'Root'));
      await tester.pumpWidget(_KeepAliveHarness(panes: [root]));
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      await tester.pumpWidget(
        _KeepAliveHarness(
          panes: [
            root,
            _pane('A', child: const ColoredBox(color: Colors.blue)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);
      expect(find.text('probe-Root'), findsOneWidget);
    });

    testWidgets('single column depth 1 to 2 keeps the root pane State', (
      tester,
    ) async {
      final root = _pane('Root', child: const _KeepAliveProbe(label: 'Root'));
      await tester.pumpWidget(
        _KeepAliveHarness(panes: [root], visibleCount: 1),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      await tester.pumpWidget(
        _KeepAliveHarness(panes: [root, _pane('A')], visibleCount: 1),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);
    });
  });
}

SlidingPane _pane(String name, {Widget? child}) {
  return SlidingPane(
    key: ValueKey<String>(name),
    title: signal(name),
    child: child ?? ColoredBox(color: Colors.grey, child: Text(name)),
  );
}

class _KeepAliveProbe extends StatefulWidget {
  const _KeepAliveProbe({required this.label});

  final String label;
  static int initCount = 0;

  @override
  State<_KeepAliveProbe> createState() => _KeepAliveProbeState();
}

class _KeepAliveProbeState extends State<_KeepAliveProbe> {
  @override
  void initState() {
    super.initState();
    _KeepAliveProbe.initCount++;
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('probe-${widget.label}'));
  }
}

class _KeepAliveHarness extends StatelessWidget {
  const _KeepAliveHarness({required this.panes, this.visibleCount = 2});

  final List<SlidingPane> panes;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SlidingPaneViewport(panes: panes, visibleCount: visibleCount),
        ),
      ),
    );
  }
}
