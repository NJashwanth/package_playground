import 'package:flutter_test/flutter_test.dart';

import 'package:package_playground/main.dart';

void main() {
  test('lifecycle store accepts and clears events', () {
    final store = LifecycleStore.instance;

    store.clear();
    expect(store.events.value, isEmpty);
  });
}
