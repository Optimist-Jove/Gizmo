import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('GizmoApp renders initial phone authentication screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GizmoApp());

    expect(find.text('Gizmo Messaging'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
  });
}
