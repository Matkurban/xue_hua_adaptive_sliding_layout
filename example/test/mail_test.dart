import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} mail', () {
      testWidgets('folder then thread builds the URL stack', (tester) async {
        final router = await pumpExample(tester, width: width);
        await tester.tap(find.byKey(const Key('folder-inbox')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox');
        await tester.tap(find.byKey(const Key('thread-1')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox/1');
        expect(find.textContaining('Welcome'), findsWidgets);
      });
    });
  }

  testWidgets('400 pushed page hides the NavigationBar', (tester) async {
    await pumpExample(tester, width: 400);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byKey(const Key('folder-inbox')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  group('1200 mail panes', () {
    testWidgets('pushReplacementNamed switches folder in place', (
      tester,
    ) async {
      final router = await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('switch-folder-sent')));
      await tester.pumpAndSettle();
      expect(router.location.value, '/mail/sent');
      expect(find.text('Re: calendar'), findsOneWidget);
    });

    testWidgets('breadcrumb popUntil returns to Mail', (tester) async {
      final router = await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('thread-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AdaptiveBreadcrumbs),
          matching: find.text('Mail'),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.location.value, '/mail');
      expect(find.byKey(const Key('folder-inbox')), findsOneWidget);
    });

    testWidgets('onExit Stay keeps the reply draft', (tester) async {
      final router = await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('thread-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-reply')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reply-draft')), 'draft');
      await tester.pump();
      final pending = router.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(await pending, isFalse);
      expect(router.location.value, '/mail/inbox/1/reply');
    });

    testWidgets('pop skips onExit and leaves the draft', (tester) async {
      final router = await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('thread-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-reply')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('reply-draft')), 'draft');
      await tester.pump();
      router.pop();
      await tester.pumpAndSettle();
      expect(router.location.value, '/mail/inbox/1');
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('fullscreen photo overlays the shell', (tester) async {
      final router = await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('thread-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-attachment')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo-id')), findsOneWidget);
      expect(router.location.value, '/photo/mail-1');
    });

    testWidgets('dragging the sash changes pane widths', (tester) async {
      await pumpExample(tester);
      await tester.tap(find.byKey(const Key('folder-inbox')));
      await tester.pumpAndSettle();
      final handle = find.byKey(SlidingPaneViewport.resizeHandleKey);
      expect(handle, findsOneWidget);
      final before = tester
          .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
          .width;
      await tester.drag(handle, const Offset(60, 0), touchSlopX: 0);
      await tester.pumpAndSettle();
      final after = tester
          .getSize(find.byKey(SlidingPaneViewport.visibleLeftPaneKey))
          .width;
      expect(after, isNot(equals(before)));
    });
  });
}
