import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_adaptive_sliding_layout/xue_hua_adaptive_sliding_layout.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/demo_pages.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/main.dart';

const Size compactSize = Size(400, 800);
const Size mediumSize = Size(700, 800);
const Size expandedSize = Size(900, 800);

List<String> _names(int tab) {
  return demoShell.stacks[tab].pages.value.map((page) => page.name).toList();
}

List<String> _visibleNames(int tab, int visibleCount) {
  return demoShell.stacks[tab]
      .visiblePages(visibleCount)
      .map((page) => page.name)
      .toList();
}

const List<String> _deepStackNames = [
  'Home',
  DemoRoutes.inbox,
  DemoRoutes.thread,
  DemoRoutes.reply,
  DemoRoutes.attachment,
];

Future<void> _openToAttachment(WidgetTester tester) async {
  await tester.tap(find.byKey(DemoKeys.openInbox));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(DemoKeys.openThread));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(DemoKeys.openReply));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(DemoKeys.openAttachment));
  await tester.pumpAndSettle();
}

Future<void> _pumpDemo(WidgetTester tester, Size size) async {
  resetDemo();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    resetDemo();
  });
  await tester.pumpWidget(const DemoApp());
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo shell shows Home entries', (tester) async {
    await _pumpDemo(tester, expandedSize);
    expect(find.byKey(DemoKeys.openInbox), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets(
    'compact Inbox uses fallback Navigator and leaves sliding stack at root',
    (tester) async {
      await _pumpDemo(tester, compactSize);
      expect(demoShell.isSlidingActive, isFalse);
      expect(find.byKey(DemoKeys.navBar), findsOneWidget);

      await tester.tap(find.byKey(DemoKeys.openInbox));
      await tester.pumpAndSettle();

      expect(find.byType(InboxPage), findsOneWidget);
      expect(find.text('Message list'), findsOneWidget);
      expect(_names(0), ['Home']);
      expect(demoNavKey.currentState!.canPop(), isTrue);

      demoNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(InboxPage), findsNothing);
      expect(find.byKey(DemoKeys.openInbox), findsOneWidget);
    },
  );

  testWidgets('expanded Inbox is peer replace with breadcrumbs', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    expect(demoShell.isSlidingActive, isTrue);
    expect(
      LayoutBreakpoints.visibleColumnCount(demoShell.viewportWidth.value),
      2,
    );

    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home', DemoRoutes.inbox]);
    expect(find.text('Home'), findsWidgets);
    expect(find.byType(InboxPage), findsOneWidget);
    expect(find.byType(HomeTab), findsOneWidget);
    expect(find.text('Inbox'), findsWidgets);
  });

  testWidgets('medium Inbox uses one-column sliding stack', (tester) async {
    await _pumpDemo(tester, mediumSize);
    expect(demoShell.isSlidingActive, isTrue);
    expect(
      LayoutBreakpoints.visibleColumnCount(demoShell.viewportWidth.value),
      1,
    );

    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home', DemoRoutes.inbox]);
    expect(find.byType(InboxPage), findsOneWidget);
  });

  testWidgets('expanded Inbox then Thread is depth 3 with extra', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DemoKeys.openThread));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home', DemoRoutes.inbox, DemoRoutes.thread]);
    expect(demoShell.stacks[0].depth, 3);
    expect(find.text('thread-id:42'), findsOneWidget);
    expect(find.text('thread-extra:hello-extra'), findsOneWidget);
    expect(find.text('thread-ref:inbox'), findsOneWidget);
  });

  testWidgets('expanded openSecondary from depth 3 returns to depth 2', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DemoKeys.openThread));
    await tester.pumpAndSettle();
    expect(demoShell.stacks[0].depth, 3);

    await tester.tap(find.byKey(const Key('inbox-open-peer')));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home', DemoRoutes.peer]);
    expect(find.byType(PeerPage), findsOneWidget);
    expect(find.byType(ThreadPage), findsNothing);
  });

  testWidgets('expanded pushReplacementNamed replaces stack top only', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inbox-replace-top')));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home', DemoRoutes.replaced]);
    expect(find.byType(ReplacedPage), findsOneWidget);
    expect(find.byType(InboxPage), findsNothing);
  });

  testWidgets('expanded photo is not intercepted', (tester) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openPhoto));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home']);
    expect(find.byType(PhotoPage), findsOneWidget);
    expect(find.text('Photo fullscreen'), findsOneWidget);
    expect(demoNavKey.currentState!.canPop(), isTrue);
  });

  testWidgets('expanded chat replaces peer on Explore tab', (tester) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openChat));
    await tester.pumpAndSettle();

    expect(demoShell.currentIndex.value, 1);
    expect(_names(0), ['Home']);
    expect(_names(1), ['Explore', DemoRoutes.chat]);
    expect(find.byType(ChatPage), findsOneWidget);
  });

  testWidgets('expanded popToRoot returns to Home', (tester) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DemoKeys.openThread));
    await tester.pumpAndSettle();
    expect(demoShell.stacks[0].depth, 3);

    await tester.tap(find.byKey(const Key('inbox-pop-to-root')));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home']);
    expect(find.byType(HomeTab), findsOneWidget);
    expect(find.byType(ThreadPage), findsNothing);
  });

  testWidgets('tab stacks stay isolated', (tester) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();
    expect(_names(0), ['Home', DemoRoutes.inbox]);

    await tester.tap(
      find.descendant(
        of: find.byKey(DemoKeys.navRail),
        matching: find.text('Explore'),
      ),
    );
    await tester.pumpAndSettle();
    expect(demoShell.currentIndex.value, 1);
    expect(_names(1), ['Explore']);

    await tester.tap(
      find.descendant(
        of: find.byKey(DemoKeys.navRail),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();
    expect(demoShell.currentIndex.value, 0);
    expect(_names(0), ['Home', DemoRoutes.inbox]);
    expect(find.byType(InboxPage), findsOneWidget);
  });

  testWidgets('report updates breadcrumb title', (tester) async {
    await _pumpDemo(tester, expandedSize);
    await tester.tap(find.byKey(DemoKeys.openInbox));
    await tester.pumpAndSettle();
    expect(demoShell.stacks[0].pages.value.last.title.value, 'Inbox');

    await tester.tap(find.byKey(DemoKeys.reportTitle));
    await tester.pumpAndSettle();

    expect(demoShell.stacks[0].pages.value.last.title.value, 'Alice');
    expect(find.text('Alice'), findsWidgets);
  });

  testWidgets(
    'expanded Inbox Thread Reply Attachment is depth 5 with last two columns',
    (tester) async {
      await _pumpDemo(tester, expandedSize);
      await _openToAttachment(tester);

      expect(_names(0), _deepStackNames);
      expect(demoShell.stacks[0].depth, 5);
      expect(_visibleNames(0, 2), [DemoRoutes.reply, DemoRoutes.attachment]);
      expect(find.byType(ReplyPage), findsOneWidget);
      expect(find.byType(AttachmentPage), findsOneWidget);
      expect(find.text('reply-extra:hello-extra'), findsOneWidget);
      expect(find.text('attachment-id:1'), findsOneWidget);
      expect(find.text('attachment-extra:file-a'), findsOneWidget);
    },
  );

  testWidgets('expanded pop from Attachment returns to Reply at depth 4', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    await _openToAttachment(tester);
    expect(demoShell.stacks[0].depth, 5);

    demoNavigator.pop();
    await tester.pumpAndSettle();

    expect(_names(0), [
      'Home',
      DemoRoutes.inbox,
      DemoRoutes.thread,
      DemoRoutes.reply,
    ]);
    expect(demoShell.stacks[0].depth, 4);
    expect(_visibleNames(0, 2), [DemoRoutes.thread, DemoRoutes.reply]);
    expect(find.byType(AttachmentPage), findsNothing);
    expect(find.byType(ReplyPage), findsOneWidget);
    expect(find.text('reply-extra:hello-extra'), findsOneWidget);
  });

  testWidgets(
    'expanded openAfter from Reply replaces right Attachment and stays depth 5',
    (tester) async {
      await _pumpDemo(tester, expandedSize);
      await _openToAttachment(tester);
      expect(_visibleNames(0, 2), [DemoRoutes.reply, DemoRoutes.attachment]);

      await tester.tap(find.byKey(DemoKeys.openOtherAttachment));
      await tester.pumpAndSettle();

      expect(_names(0), _deepStackNames);
      expect(demoShell.stacks[0].depth, 5);
      expect(_visibleNames(0, 2), [DemoRoutes.reply, DemoRoutes.attachment]);
      expect(find.byType(ReplyPage), findsOneWidget);
      expect(find.byType(AttachmentPage), findsOneWidget);
      expect(find.text('attachment-id:99'), findsOneWidget);
      expect(find.text('attachment-extra:other-file'), findsOneWidget);
      expect(find.text('attachment-id:1'), findsNothing);
    },
  );

  testWidgets('expanded popToRoot from depth 5 returns to Home', (
    tester,
  ) async {
    await _pumpDemo(tester, expandedSize);
    await _openToAttachment(tester);
    expect(demoShell.stacks[0].depth, 5);

    await tester.tap(find.byKey(const Key('reply-pop-to-root')));
    await tester.pumpAndSettle();

    expect(_names(0), ['Home']);
    expect(demoShell.stacks[0].depth, 1);
    expect(find.byType(HomeTab), findsOneWidget);
    expect(find.byType(AttachmentPage), findsNothing);
    expect(find.byType(ReplyPage), findsNothing);
  });

  testWidgets(
    'compact Attachment uses fallback Navigator and leaves sliding stack at root',
    (tester) async {
      await _pumpDemo(tester, compactSize);
      expect(demoShell.isSlidingActive, isFalse);
      await _openToAttachment(tester);

      expect(_names(0), ['Home']);
      expect(demoShell.stacks[0].depth, 1);
      expect(find.byType(AttachmentPage), findsOneWidget);
      expect(find.text('attachment-id:1'), findsOneWidget);
      expect(demoNavKey.currentState!.canPop(), isTrue);

      demoNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(ReplyPage), findsOneWidget);
      expect(_names(0), ['Home']);

      demoNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(ThreadPage), findsOneWidget);
      expect(_names(0), ['Home']);

      demoNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(InboxPage), findsOneWidget);
      expect(_names(0), ['Home']);

      demoNavigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(InboxPage), findsNothing);
      expect(find.byKey(DemoKeys.openInbox), findsOneWidget);
      expect(_names(0), ['Home']);
      expect(demoNavKey.currentState!.canPop(), isFalse);
    },
  );
}
