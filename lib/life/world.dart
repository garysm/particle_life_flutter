import 'dart:collection';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:p5/p5.dart';
import 'package:particle_life_flutter/life/particle_updater.dart';
import 'package:particle_life_flutter/pointmanagement/point_manager.dart';

import 'camera.dart';
import 'color_maker.dart';
import 'helper.dart';
import 'matrix.dart';
import 'particle.dart';

class World {
  static const double boxMargin = 0.5;
  double? particleDensity = 0.002;
  num boxWidth;
  num boxHeight;
  double friction = 9.0;
  double heat = 0.0;
  double forceFactor = 950.0;
  late int nParticles;
  int rMin = 10;
  int? rMax = 40;
  int particleSize = 2;
  bool wrapWorld = true;
  int spawnMode = 0;

  Matrix? matrix;
  Matrix? requestedMatrix;
  int nextMatrixSize = 6;
  late HashMap<int, Color> typeColorMap;
  List<MatrixInitializer> matrixInitializers = [];
  List<String> matrixInitializerNames = [];
  int? currentMatrixInitializerIndex = 0;
  int? requestedMatrixInitializerIndex;

  Random random = Random();

  late PointManager pm;
  ParticleUpdater pointUpdater = ParticleUpdater();

  bool resetRequested = false;
  bool respawnRequested = false;
  int? requestedRMax;
  double? requestedParticleDensity;

  bool drawParticleManager = false;
  bool drawForceDiagram = false;
  bool drawRenderingStats = false;

  num mouseX = 0;
  num mouseY = 0;
  num lastMouseX = 0;
  num lastMouseY = 0;
  num draggedDistanceSquared = 0;
  bool isMousePressed = false;
  Camera? camera;
  num cameraFocusSelectionRadius = 25.0;

  num particleDragSelectionRadius = 25.0;

  bool screenshotRequested = false;

  World(this.boxWidth, this.boxHeight, this.camera) {
    // init vars that depend on other vars
    requestedMatrixInitializerIndex = currentMatrixInitializerIndex;
    requestedRMax = rMax;
    requestedParticleDensity = particleDensity;

    nParticles = calcParticleCount();

    pm = createNewPointManager();

    init();
  }

  int calcParticleCount() {
    return (particleDensity! * boxWidth * boxHeight).floor();
  }

  PointManager createNewPointManager() {
    return PointManager(rMax!, particleDensity!, 0, boxWidth, 0, boxHeight);
  }

  void recreatePointManager() {
    PointManager oldPointManager = pm;
    pm = createNewPointManager();
    AllIterator all = oldPointManager.getAllWithRelevant(wrapWorld);
    while (all.moveNext()) {
      pm.add(all.current);
    }
  }

  void stop() {}

  void init() {
    initAttractionSetters();
    makeMatrix();
    calcColors();
    spawnParticles();
  }

  void requestNewRMax(int newRMax) {
    requestedRMax = newRMax;
  }

  void requestMatrixSize(int matrixSize) {
    nextMatrixSize = matrixSize;
  }

  void requestMatrix(Matrix matrix) {
    requestedMatrix = matrix;
  }

  void requestReset() {
    resetRequested = true;
  }

  void requestRespawn() {
    respawnRequested = true;
  }

  void requestParticleDensity(double newParticleDensity) {
    requestedParticleDensity = newParticleDensity;
  }

  void reset() {
    pm.clear();
    makeMatrix();
    calcColors();
    spawnParticles();
    camera!.stopFollow();
  }

  void respawn() {
    pm.clear();
    spawnParticles();
    camera!.stopFollow();
  }

  void addAttractionSetter(String name, MatrixInitializer initializer) {
    matrixInitializerNames.add(name);
    matrixInitializers.add(initializer);
  }

  void initAttractionSetters() {
    addAttractionSetter("random f", RandomInitializer());
    addAttractionSetter("chains", ChainsInitializer());
    addAttractionSetter("random chains", RandomChainsInitializer());
    addAttractionSetter("equal pairs", EqualPairsInitializer());
  }

  void makeMatrix() {
    matrix = Matrix(
        nextMatrixSize, matrixInitializers[currentMatrixInitializerIndex!]);
  }

  void calcColors() {
    typeColorMap = HashMap();
    for (int type = 0; type < matrix!.n; type++) {
      typeColorMap.putIfAbsent(
          type, () => ColorMaker.compute(type / matrix!.n));
    }
  }

  void spawnParticles() {
    for (int i = 0; i < nParticles; i++) {
      num randomX;
      num randomY;

      num radius = min(boxWidth, boxHeight) / 3;
      switch (spawnMode) {
        case 1:
          {
            // Sphere
            double angle = 2 * pi * random.nextDouble();
            num r = radius * sqrt(random.nextDouble());
            randomX = boxWidth / 2 + r * cos(angle);
            randomY = boxHeight / 2 + r * sin(angle);
            break;
          }
        case 2:
          {
            // Centered Sphere
            double angle = 2 * pi * random.nextDouble();
            num r = radius * random.nextDouble();
            randomX = boxWidth / 2 + r * cos(angle);
            randomY = boxHeight / 2 + r * sin(angle);
            break;
          }
        case 3:
          {
            // Circle
            double angle = 2 * pi * random.nextDouble();
            num r = radius * (1 + 0.2 * random.nextDouble());
            randomX = boxWidth / 2 + r * cos(angle);
            randomY = boxHeight / 2 + r * sin(angle);
            break;
          }
        case 4:
          {
            // Spiral
            double f = random.nextDouble();
            double angle = 2 * pi * f;
            num r = radius * sqrt(f) + radius * 0.1 * random.nextDouble();
            randomX = boxWidth / 2 + r * cos(angle);
            randomY = boxHeight / 2 + r * sin(angle);
            break;
          }
        default:
          {
            randomX = boxWidth * random.nextDouble();
            randomY = boxHeight * random.nextDouble();
            break;
          }
      }

      pm.add(Particle(randomX, randomY, 0, 0, random.nextInt(matrix!.n)));
    }
  }

  void requestMatrixInitializerIndex(int index) {
    requestedMatrixInitializerIndex = index;
  }

  void keyReleased(String key) {
    switch (key) {
      case 'r':
        reset();
        break;
      case 's':
        respawn();
        break;
      case 'f':
        toggleCameraFollow();
        break;
    }
  }

  void mousePressed() {
    isMousePressed = true;

    draggedDistanceSquared = 0;

    // reset drag
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }

  void mouseReleased() {
    isMousePressed = false;

    if (draggedDistanceSquared < 3 * 3) {
      toggleCameraFollow();
    }
  }

  void setMousePos(num x, num y) {
    num dx = x - mouseX;
    num dy = y - mouseY;
    draggedDistanceSquared += dx * dx + dy * dy;

    mouseX = x;
    mouseY = y;
  }

  void toggleCameraFollow() {
    if (camera!.isFollowing()) {
      camera!.stopFollow();
    } else {
      camera!.startFollow(
          pm, mouseX, mouseY, cameraFocusSelectionRadius, wrapWorld);
    }
  }

  void updateUI() {
    if (screenshotRequested) {
      screenshotRequested = false;
    }

    if (requestedRMax != rMax || requestedParticleDensity != particleDensity) {
      rMax = requestedRMax;
      particleDensity = requestedParticleDensity;
      nParticles = calcParticleCount();
      recreatePointManager();
    }

    if (requestedMatrix != null) {
      bool matrixSizeChanged = requestedMatrix!.n != matrix!.n;
      matrix = requestedMatrix;
      requestedMatrix = null;
      nextMatrixSize = matrix!.n;
      if (matrixSizeChanged) {
        calcColors();
        respawn();
      }
    }

    if (nextMatrixSize != matrix!.n) {
      requestReset();
    }

    if (requestedMatrixInitializerIndex != currentMatrixInitializerIndex) {
      currentMatrixInitializerIndex = requestedMatrixInitializerIndex;
      requestReset();
    }

    if (resetRequested) {
      resetRequested = false;
      reset();
    } else if (respawnRequested) {
      respawnRequested = false;
      respawn();
    }
  }

  void update(num dt) {
    pm.recalculate();

    pointUpdater.setValues(
        rMin, rMax!, forceFactor, friction, heat, boxWidth, boxHeight, dt);

    AllIterator all = pm.getAllWithRelevant(wrapWorld);
    while (all.moveNext()) {
      pointUpdater.updateWithRelevant(
        all.current as Particle,
        all.getRelevant().cast<Particle>(),
        matrix,
      );
    }

    if (isMousePressed) {
      // drag all particles in a specific radius

      double dragX = mouseX - (lastMouseX as double);
      double dragY = mouseY - (lastMouseY as double);

      for (Particle particle in pm.getRelevant(
          lastMouseX, lastMouseY, wrapWorld) as Iterable<Particle>) {
        num dx = particle.x - lastMouseX;
        num dy = particle.y - lastMouseY;

        if (dx * dx + dy * dy <
            particleDragSelectionRadius * particleDragSelectionRadius) {
          particle.vx = 0;
          particle.vy = 0;

          particle.x += dragX;
          particle.y += dragY;
        }
      }
    }

    all = pm.getAll();
    while (all.moveNext()) {
      Particle particle = all.current as Particle;

      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;

      if (wrapWorld) {
        particle.x = Helper.modulo(particle.x, boxWidth);
        particle.y = Helper.modulo(particle.y, boxHeight);
      } else {
        // stop particles at the boundaries

        if (particle.x < boxMargin) {
          particle.x = boxMargin;
          particle.vx = -particle.vx;
        } else if (particle.x > boxWidth - boxMargin) {
          particle.x = boxWidth - boxMargin;
          particle.vx = -particle.vx;
        }
        if (particle.y < boxMargin) {
          particle.y = boxMargin;
          particle.vy = -particle.vy;
        } else if (particle.y > boxHeight - boxMargin) {
          particle.y = boxHeight - boxMargin;
          particle.vy = -particle.vy;
        }
      }
    }

    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }

  void draw(PPainter context) {
    drawParticles(context);

    // if (drawParticleManager) {
    //   context.push();
    //   pm.draw(context);
    //   context.pop();
    // }

    if (isMousePressed &&
        !camera!.isFollowing() &&
        (camera!.getScale() - 1).abs() < 0.1) {
      context.push();
      context.noFill();
      context.stroke(context.color(32, 32, 32));
      context.ellipse(
          mouseX as double,
          mouseY as double,
          2 * (particleDragSelectionRadius as double),
          2 * (particleDragSelectionRadius as double));
      context.pop();
    }

    // if (drawForceDiagram) {
    //   context.push();
    //   drawForces(context);
    //   context.pop();
    // }

    // if (drawRenderingStats) {
    //   context.push();
    //   context.textAlign(context.RIGHT, context.BOTTOM);
    //   context.fill(255);
    //   context.text(nParticles, context.width, context.height);
    //   context.pop();
    // }
  }

  void drawParticles(PPainter context) {
    context.push();
    context.noStroke();
    AllIterator all = pm.getAll();
    final num halfParticleSize = particleSize / 2;
    while (all.moveNext()) {
      Particle particle = all.current as Particle;
      context.fill(getColor(particle.type)!);
      context.rect(
        particle.x - (halfParticleSize as double),
        particle.y - halfParticleSize,
        particleSize.toDouble(),
        particleSize.toDouble(),
      );
    }
    context.pop();
  }

  Color? getColor(int? type) {
    return typeColorMap[type];
  }

  // void drawForces(PPainter context) {
  //   context.push();

  //   num size = 20;

  //   context.translate(context.width - size * (matrix.n + 1), 0);

  //   context.translate(size/2, size/2);

  //   for (int type = 0; type < matrix.n; type++) {
  //     context.fill(typeColorMap.get(type));
  //     context.ellipse(size + type * size, 0, size / 2, size / 2);
  //     context.ellipse(0, size + type * size, size / 2, size / 2);
  //   }

  //   context.translate(size / 2, size / 2);
  //   context.textAlign(context.CENTER, context.CENTER);
  //   for (int i = 0; i < matrix.n; i++) {
  //     for (int j = 0; j < matrix.n; j++) {

  //       num attraction = matrix.get(i, j);

  //       if (attraction > 0) {
  //         num c = 255 * attraction;
  //         context.fill(0, c, 0);
  //       } else {
  //         num c = -255 * attraction;
  //         context.fill(c, 0, 0);
  //       }

  //       context.rect(j * size, i * size, size, size);

  //       context.fill(255);
  //       context.text(String.format("%.0f", attraction * 10), (j + 0.5f) * size, (i + 0.5f) * size);
  //     }
  //   }

  //   context.fill(255);
  //   context.textAlign(context.RIGHT);
  //   context.text(String.format("%s [%d]",
  //     matrixInitializerNames.get(currentMatrixInitializerIndex),
  //     currentMatrixInitializerIndex
  //   ), size * matrix.n, size * matrix.n + size);

  //   context.pop();
  // }

  bool shouldDrawRenderingStats() {
    return drawRenderingStats;
  }

  void requestScreenshot() {
    screenshotRequested = true;
  }

  bool isScreenshotRequested() {
    return screenshotRequested;
  }
}
