import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} settings', () {
      testWidgets('account redirects to login then returns', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(2);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-account')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Sign in'), findsWidgets);
        expect(signedIn.value, isFalse);
        await tester.tap(find.byKey(const Key('sign-in')));
        await tester.pumpAndSettle();
        expect(find.text('Sign out and refresh()'), findsOneWidget);
        expect(router.location.value, '/settings/account');
      });

      testWidgets('missing route shows errorBuilder', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(2);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-about')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-404')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('not-found-uri')), findsOneWidget);
        expect(router.location.value, contains('this-does-not-exist'));
      });
    });
  }

  testWidgets('sign out refresh redirects back to login', (tester) async {
    final router = await pumpExample(tester);
    signedIn.value = true;
    router.goBranch(2);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sign in'), findsWidgets);
  });
}
