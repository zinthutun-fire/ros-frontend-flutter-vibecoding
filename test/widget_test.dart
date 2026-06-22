import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waiter_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WaiterApp()));
    await tester.pumpAndSettle();
    expect(find.text('Restaurant Waiter'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
