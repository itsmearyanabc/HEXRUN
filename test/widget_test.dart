import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexrun/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // We override routerProvider to avoid Firebase dependent Auth redirect
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(
            GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(body: Text('Mock Map Page')),
                ),
              ],
            ),
          ),
        ],
        child: const HexRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HexRunApp), findsOneWidget);
    expect(find.text('Mock Map Page'), findsOneWidget);
  });
}
