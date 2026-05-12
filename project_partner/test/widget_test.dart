import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_partner/app.dart';

void main() {
  testWidgets('App boots into the splash screen when signed out',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ProjectPartnerApp()),
    );
    // Settle initial frames + the first emit from the auth stream.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Project Partner'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
