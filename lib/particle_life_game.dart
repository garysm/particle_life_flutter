import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';

class ParticleLifeGame extends FlameGame
    with SingleGameInstance, ScaleDetector {
  ParticleLifeGame();

  late final CameraComponent cameraComponent;

  static const double screenWidth = 800;
  static const double screenHeight = 600;
  static const int particlesCount = 100;

  final world = World();

  @override
  Future<void> onLoad() async {
    await add(world);
    cameraComponent = CameraComponent.withFixedResolution(
      width: screenWidth,
      height: screenHeight,
      world: world,
    );
    cameraComponent.viewfinder.anchor = Anchor.topLeft;
    await add(cameraComponent);
    world.add(Background());
    // generate a list of particles in different positions in the screen size.  The positions should not be too close to the edges.
    final random = Random();
    final List<Particle> particles = _seedParticles(random);
    world.addAll(particles);
    children.register<Particle>();
  }

  List<Particle> _seedParticles(Random random) {
    return List.generate(
      particlesCount,
      (index) {
        final x = random.nextDouble() * (screenWidth - 20) + 10;
        final y = random.nextDouble() * (screenHeight - 20) + 10;
        return Particle(
          index,
          position: Vector2(
            x,
            y,
          ),
        );
      },
    );
  }
}

class Particle extends PositionComponent with HasGameRef<ParticleLifeGame> {
  Particle(this.id, {required super.position})
      : super(
          size: Vector2.all(5),
          anchor: Anchor.center,
        );

  final int id;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset.zero,
      size.x,
      Paint()..color = const Color(0xFF00FF00),
    );
  }

  @override
  void update(double dt) {
    final allParticles = gameRef.world.children.query<Particle>();
    final otherParticles = allParticles.where((particle) => particle.id != id);

    final nearbyParticles = otherParticles.where(
      (particle) {
        final distance = (particle.position - position).length;
        return distance < 100;
      },
    );
  }
}

class Background extends PositionComponent {
  @override
  int priority = -1;

  late Paint black;
  late final Rect hugeRect;

  Background() : super(size: Vector2.all(100000), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    black = BasicPalette.black.paint();
    hugeRect = size.toRect();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(hugeRect, black);
  }
}
