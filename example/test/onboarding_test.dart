import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xue_hua_adaptive_sliding_layout_example/data/auth.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} onboarding', () {
      testWidgets('app starts on onboarding and Enter home opens mail', (
        tester,
      ) async {
        final router = await pumpExample(
          tester,
          width: width,
          enterHome: false,
        );
        expect(router.location.value, '/onboarding');
        expect(find.byKey(const Key('onboarding-home')), findsOneWidget);
        await tester.tap(find.byKey(const Key('onboarding-home')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/mail');
        expect(find.byKey(const Key('folder-inbox')), findsOneWidget);
        expect(router.canPop(), isFalse);
      });

      testWidgets('Log in signs in and lands on mail', (tester) async {
        final router = await pumpExample(
          tester,
          width: width,
          enterHome: false,
        );
        await tester.tap(find.byKey(const Key('onboarding-login')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/login');
        await tester.tap(find.byKey(const Key('sign-in')));
        await tester.pumpAndSettle();
        expect(signedIn.value, isTrue);
        expect(router.location.value, '/mail');
      });

      testWidgets('Register toggles with Log in and registers', (
        tester,
      ) async {
        final router = await pumpExample(
          tester,
          width: width,
          enterHome: false,
        );
        await tester.tap(find.byKey(const Key('onboarding-register')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/register');
        await tester.tap(find.byKey(const Key('go-login')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/login');
        await tester.tap(find.byKey(const Key('go-register')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/register');
        expect(router.matches.value.matches, hasLength(2));
        await tester.tap(find.byKey(const Key('register-submit')));
        await tester.pumpAndSettle();
        expect(signedIn.value, isTrue);
        expect(router.location.value, '/mail');
      });
    });
  }
}
