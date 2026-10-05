import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewind/ui/widgets/common.dart';

void main() {
  testWidgets('REWIND logo and score ring render', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          RewindLogo(),
          ScoreRing(score: 72, size: 160),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('REWIND'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
  });
}
