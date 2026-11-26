import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fretmaster/core/di/injection_container.dart' as di;
import 'package:fretmaster/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initServiceLocator();
  });

  testWidgets('Home page menampilkan branding FretMaster dan fitur utama', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const FretMasterApp());
    await tester.pumpAndSettle();

    expect(find.text('FRETMASTER'), findsOneWidget);
    expect(find.text('Live Scanner'), findsOneWidget);
    expect(find.text('Drill Transisi'), findsOneWidget);
    expect(find.text('Kamus Akord'), findsOneWidget);
    expect(find.text('Riwayat Sesi'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
