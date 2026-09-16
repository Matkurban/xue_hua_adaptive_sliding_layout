import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} round trip', () {
      testWidgets('setNewRoutePath restores a deep mail URL', (tester) async {
        final router = await pumpExample(tester, width: width);
        await router.routerDelegate.setNewRoutePath(
          router.registry.match(Uri.parse('/mail/inbox/3')),
        );
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox/3');
        expect(find.textContaining('Deep link friendly'), findsWidgets);
      });

      testWidgets('branch location is remembered', (tester) async {
        final router = await pumpExample(tester, width: width);
        await tester.tap(find.byKey(const Key('folder-inbox')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox');
        router.goBranch(1);
        await tester.pumpAndSettle();
        expect(router.location.value, '/contacts');
        router.goBranch(0);
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox');
        expect(find.byKey(const Key('thread-1')), findsOneWidget);
      });
    });
  }
}
