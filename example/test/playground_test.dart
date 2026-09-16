import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} playground', () {
      testWidgets('cross-branch pushNamed rebuilds mail', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(3);
        await tester.pumpAndSettle();
        expect(router.location.value, '/playground');
        await router.pushNamed('/mail/inbox/3');
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail/inbox/3');
        expect(find.textContaining('Deep link friendly'), findsWidgets);
      });

      testWidgets('pushNamed color returns a result', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(3);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pg-push-color')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/playground/color');
        await tester.tap(find.byKey(const Key('pick-red')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/playground');
        expect(find.textContaining('result='), findsWidgets);
      });
    });
  }

  testWidgets('pushNamed fullscreen photo from playground', (tester) async {
    final router = await pumpExample(tester);
    router.goBranch(3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pg-push-photo')));
    await tester.pumpAndSettle();
    expect(router.location.value, '/photo/pg');
    expect(find.byKey(const Key('photo-id')), findsOneWidget);
  });
}
