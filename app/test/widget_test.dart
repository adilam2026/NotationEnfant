// Widget smoke tests for pieces of the UI that don't depend on a live
// Supabase connection (screens wired to providers are covered by manual
// testing, see README).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mes_etoiles/widgets/empty_state.dart';
import 'package:mes_etoiles/widgets/star_progress_bar.dart';
import 'package:mes_etoiles/screens/onboarding/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EmptyState shows title and triggers action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: EmptyState(
        emoji: '🌱',
        title: 'Rien pour le moment',
        actionLabel: 'Ajouter',
        onAction: () => tapped = true,
      ),
    ));

    expect(find.text('Rien pour le moment'), findsOneWidget);
    await tester.tap(find.text('Ajouter'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('StarProgressBar shows current/target', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StarProgressBar(current: 12, target: 20)),
    ));
    expect(find.text('12 / 20'), findsOneWidget);
  });

  testWidgets('Onboarding has 3 pages max and calls onDone on last "Commencer"',
      (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onDone: () => done = true),
    ));

    expect(find.text('Suivant'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Commencer'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pump();
    expect(done, isTrue);
  });
}
