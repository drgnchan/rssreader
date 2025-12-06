import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:readyou/app.dart';

void main() {
  testWidgets('App renders login flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReadyYouApp()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
