import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    group('${width.toInt()} contacts', () {
      testWidgets('namedLocation opens a contact', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(1);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact-1')));
        await tester.pumpAndSettle();
        expect(router.location.value, '/contacts/1');
        expect(find.text('Edit'), findsOneWidget);
      });

      testWidgets('await pushNamed result after save', (tester) async {
        final router = await pumpExample(tester, width: width);
        router.goBranch(1);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('contact-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit-contact')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('save-contact')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Saved'), findsWidgets);
        expect(router.location.value, '/contacts/1');
      });
    });
  }

  testWidgets('search writes q into the URL', (tester) async {
    final router = await pumpExample(tester);
    router.goBranch(1);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('contacts-search')), 'ada');
    await tester.pumpAndSettle();
    expect(router.location.value, '/contacts?q=ada');
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });
}
