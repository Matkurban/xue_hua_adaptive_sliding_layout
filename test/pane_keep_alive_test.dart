import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SlidingWindowViewport keep-alive', () {
    late SlidingWindowController controller;

    setUp(() {
      controller = SlidingWindowController();
      _KeepAliveProbe.initCount = 0;
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('depth 2 to 3 keeps the previous right pane State', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const ColoredBox(color: Colors.grey),
      );
      controller.push((_) => const _KeepAliveProbe(label: 'A'), name: 'A');

      await tester.pumpWidget(
        _KeepAliveHarness(controller: controller, visibleCount: 2),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      controller.push((_) => const ColoredBox(color: Colors.green), name: 'B');
      await tester.pumpAndSettle();

      expect(_KeepAliveProbe.initCount, 1);
      expect(find.text('probe-A'), findsOneWidget);
    });

    testWidgets('depth 1 to 2 keeps the root pane State', (tester) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const _KeepAliveProbe(label: 'Root'),
      );

      await tester.pumpWidget(
        _KeepAliveHarness(controller: controller, visibleCount: 2),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      controller.push((_) => const ColoredBox(color: Colors.blue), name: 'A');
      await tester.pumpAndSettle();

      expect(_KeepAliveProbe.initCount, 1);
      expect(find.text('probe-Root'), findsOneWidget);
    });

    testWidgets('single column depth 1 to 2 keeps the root pane State', (
      tester,
    ) async {
      controller.ensureRoot(
        name: 'Root',
        builder: (_) => const _KeepAliveProbe(label: 'Root'),
      );

      await tester.pumpWidget(
        _KeepAliveHarness(controller: controller, visibleCount: 1),
      );
      await tester.pumpAndSettle();
      expect(_KeepAliveProbe.initCount, 1);

      controller.push((_) => const ColoredBox(color: Colors.blue), name: 'A');
      await tester.pumpAndSettle();

      expect(_KeepAliveProbe.initCount, 1);
    });
  });
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
  const _KeepAliveHarness({
    required this.controller,
    required this.visibleCount,
  });

  final SlidingWindowController controller;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SlidingWindowScope(
            controller: controller,
            child: SlidingWindowViewport(
              controller: controller,
              visibleCount: visibleCount,
            ),
          ),
        ),
      ),
    );
  }
}
