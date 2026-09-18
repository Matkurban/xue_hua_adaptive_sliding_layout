import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({List<String> calls, List<bool> handlesBack}) mockSystemNavigator(
    WidgetTester tester,
  ) {
    final calls = <String>[];
    final handlesBack = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          handlesBack.add(call.arguments as bool);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    return (calls: calls, handlesBack: handlesBack);
  }

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} exit confirm', () {
      testWidgets('system back at home shows dialog; Stay keeps the app', (
        tester,
      ) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final mock = mockSystemNavigator(tester);
        final router = await pumpExample(tester, width: width);
        expect(mock.handlesBack, isNotEmpty);
        expect(mock.handlesBack.last, isTrue);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsOneWidget);
        await tester.tap(find.byKey(const Key('exit-stay')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsNothing);
        expect(router.location.value, '/mail');
        expect(mock.calls, isNot(contains('SystemNavigator.pop')));
        expect(mock.handlesBack, isNotEmpty);
        expect(mock.handlesBack.last, isTrue);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsOneWidget);
        expect(mock.calls, isNot(contains('SystemNavigator.pop')));
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));

      testWidgets('Exit sends SystemNavigator.pop', (tester) async {
        final mock = mockSystemNavigator(tester);
        await pumpExample(tester, width: width);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('exit-confirm')));
        await tester.pumpAndSettle();
        expect(mock.calls, contains('SystemNavigator.pop'));
      });

      testWidgets('system back on a deeper page pops without the dialog', (
        tester,
      ) async {
        final router = await pumpExample(tester, width: width);
        await tester.tap(find.byKey(const Key('folder-inbox')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox');
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail');
        expect(find.byKey(const Key('exit-dialog')), findsNothing);
      });

      testWidgets('Escape at home does not show the exit dialog', (
        tester,
      ) async {
        await pumpExample(tester, width: width);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsNothing);
      });

      testWidgets('system back while the dialog is up closes the dialog', (
        tester,
      ) async {
        final router = await pumpExample(tester, width: width);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsOneWidget);
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('exit-dialog')), findsNothing);
        expect(router.location.value, '/mail');
      });
    });
  }
}
