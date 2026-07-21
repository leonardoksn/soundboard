import 'package:flutter_test/flutter_test.dart';
import 'package:soundboard/models/sound.dart';

void main() {
  test('fromMap/toMap faz round-trip preservando os campos', () {
    final map = {
      'id': 1,
      'name': 'Risada',
      'file_path': '/dados/sounds/abc.mp3',
      'color': 0xFFEF5350,
      'position': 2,
      'loop': 1,
    };
    final sound = Sound.fromMap(map);
    expect(sound.id, 1);
    expect(sound.name, 'Risada');
    expect(sound.filePath, '/dados/sounds/abc.mp3');
    expect(sound.color, 0xFFEF5350);
    expect(sound.position, 2);
    expect(sound.loop, isTrue);
    expect(sound.toMap(), map);
  });

  test('toMap omite id quando null', () {
    const sound = Sound(
      name: 'Novo',
      filePath: '/x.mp3',
      color: 0xFF000000,
      position: 0,
    );
    expect(sound.toMap().containsKey('id'), isFalse);
  });

  test('copyWith troca apenas o campo informado', () {
    const sound = Sound(
      id: 5,
      name: 'A',
      filePath: '/a.mp3',
      color: 1,
      position: 0,
    );
    final renamed = sound.copyWith(name: 'B');
    expect(renamed.name, 'B');
    expect(renamed.id, 5);
    expect(renamed.filePath, '/a.mp3');
  });
}
