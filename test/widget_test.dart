import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumaatophon/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    setupDependencyInjection();
    await tester.pumpWidget(const PhoneShopApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
