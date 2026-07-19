import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';
import 'package:soundboard/ui/sound_button.dart';

void main() {
  const sound = Sound(
    id: 1,
    name: 'Risada',
    filePath: '/a.mp3',
    color: 0xFFEF5350,
    position: 0,
  );

  testWidgets('mostra o nome e dispara onTap/onEdit', (tester) async {
    var tapped = 0;
    var edited = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoundButton(
          sound: sound,
          onTap: () => tapped++,
          onEdit: () => edited++,
        ),
      ),
    ));

    expect(find.text('Risada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    expect(edited, 1);
    expect(tapped, 0);

    await tester.tap(find.text('Risada'));
    await tester.pump();
    expect(tapped, 1);
  });
}
