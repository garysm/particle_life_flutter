import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:particle_life_flutter/particle_life_game.dart';

void main() {
  runApp(
    GameWidget(
      game: ParticleLifeGame(),
    ),
  );
}
