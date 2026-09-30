import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_ap/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ResidentApp(isLoggedIn: false));
    expect(find.byType(ResidentApp), findsOneWidget);
  });
}
