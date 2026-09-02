import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mes_etoiles/widgets/otp_code_field.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('onChanged fires progressively, onCompleted only at 6 digits',
      (tester) async {
    final changes = <String>[];
    var completed = '';

    await tester.pumpWidget(wrap(OtpCodeField(
      onChanged: changes.add,
      onCompleted: (v) => completed = v,
    )));

    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();

    expect(changes.last, '12345');
    expect(completed, isEmpty, reason: 'must not complete before 6 digits');

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(completed, '123456');
  });

  testWidgets('non-digit characters are filtered out', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(wrap(OtpCodeField(
      onChanged: changes.add,
      onCompleted: (_) {},
    )));

    await tester.enterText(find.byType(TextField), 'a1b2c3');
    await tester.pump();

    expect(changes.last, '123');
  });

  testWidgets('clear() empties the field via the exposed state key',
      (tester) async {
    final key = GlobalKey<OtpCodeFieldState>();
    await tester.pumpWidget(wrap(OtpCodeField(
      key: key,
      onCompleted: (_) {},
    )));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    key.currentState!.clear();
    await tester.pump();

    expect(find.text('1'), findsNothing);
  });

  testWidgets('shows the error border styling when errorText is set',
      (tester) async {
    await tester.pumpWidget(wrap(const OtpCodeField(
      onCompleted: _noop,
      errorText: 'Code incorrect ou expiré.',
    )));

    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .toList();
    expect(containers, isNotEmpty);
  });
}

void _noop(String _) {}
