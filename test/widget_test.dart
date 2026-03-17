import 'package:flutter_test/flutter_test.dart';

import 'package:package_playground/main.dart';

void main() {
  testWidgets('shows package playground title text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PackagePlaygroundApp());

    expect(find.text('Package Playground'), findsOneWidget);
  });
}
