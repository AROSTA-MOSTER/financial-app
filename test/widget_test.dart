import 'package:flutter_test/flutter_test.dart';
import 'package:light_gate_requisition/main.dart';

void main() {
  testWidgets('Light Gate Requisition Form smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LightGateRequisitionApp());
    expect(find.text('LIGHT GATE CHURCH'), findsWidgets);
    expect(find.text('DAILY REQUISITION FORM'), findsWidgets);
  });
}
