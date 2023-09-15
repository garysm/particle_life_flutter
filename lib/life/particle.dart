import 'package:particle_life_flutter/pointmanagement/point.dart';

class Particle implements Point {
  @override
  num x;
  @override
  num y;
  num vx;
  num vy;
  int type;

  Particle(this.x, this.y, this.vx, this.vy, this.type) {
    x = x;
    y = y;
    vx = vx;
    vy = vy;
    type = type;
  }
}
