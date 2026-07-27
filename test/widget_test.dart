import 'package:flutter_test/flutter_test.dart';
import 'package:my_diet_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App loads splash screen test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyDietApp(),
      ),
    );
    expect(find.text('MyDiet'), findsOneWidget);
  });
}
