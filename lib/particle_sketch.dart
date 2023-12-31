import 'dart:math';

import 'package:flutter/painting.dart';
import "package:p5/p5.dart";
import 'package:particle_life_flutter/average_tracker.dart';
import 'package:particle_life_flutter/life/camera.dart';
import 'package:particle_life_flutter/life/world.dart';

class ParticleSketch extends PPainter {
  Camera? camera;
  World? world;
  Size? lastSize;

  bool paused = false;
  DateTime lastUpdateTime = DateTime.now();
  static const double minDt = 0.05;

  final AverageTracker _fpsTracker = AverageTracker(20, 0);

  @override
  void setup() {
    fullScreen();

    world = World(100, 100, Camera(50, 50));
  }

  bool _sizeChanged() {
    return lastSize == null ||
        paintSize.width != lastSize!.width ||
        paintSize.height != lastSize!.height;
  }

  num get fps {
    return _fpsTracker.average;
  }

  @override
  void draw() {
    if (_sizeChanged()) {
      lastSize = paintSize;
      camera = Camera(paintSize.width / 2, paintSize.height / 2);
      world = World(paintSize.width, paintSize.height, camera);
    }

    DateTime now = DateTime.now();
    Duration diff = now.difference(lastUpdateTime);
    lastUpdateTime = now;

    double realDt = diff.inMicroseconds * 0.000001;
    if (realDt > 0) {
      _fpsTracker.pushValue(1 / realDt);
    }

    double dt = min(minDt, realDt);

    world!.updateUI();
    if (!paused) {
      world!.update(dt);
    }

    camera!.update(dt);

    push();
    camera!.apply(this);
    background(color(0, 0, 0));
    world!.draw(this);
    pop();
  }

  @override
  void mousePressed() {
    world!.setMousePos(mouseX, mouseY);
    world!.mousePressed();
  }

  @override
  void mouseReleased() {
    world!.setMousePos(mouseX, mouseY);
    world!.mouseReleased();
  }

  @override
  void mouseDragged() {
    world!.setMousePos(mouseX, mouseY);
  }
}
