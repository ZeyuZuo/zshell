// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zshell/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZShellApp());

    // Verify that the app title is displayed.
    expect(find.text('ZShell'), findsOneWidget);

    // Verify that navigation items are displayed.
    expect(find.text('主机列表'), findsOneWidget);
    expect(find.text('AI助手'), findsOneWidget);
    expect(find.text('快捷指令'), findsOneWidget);
    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });
}
