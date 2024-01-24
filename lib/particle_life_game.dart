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

  static const int particlesCount = 100;

  final world = World();

  @override
  Future<void> onLoad() async {
    await add(world);
    cameraComponent = CameraComponent.withFixedResolution(
      width: kScreenWidth,
      height: kSreenHeight,
      world: world,
    );
    cameraComponent.viewfinder.anchor = Anchor.topLeft;
    await add(cameraComponent);
    world.add(ParticleLifeMap());
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
        final x = random.nextDouble() * (kScreenWidth - 20) + 10;
        final y = random.nextDouble() * (kSreenHeight - 20) + 10;
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
  final int id;
  final double radius = 2.5;
  Vector2 _velocity = Vector2.zero();

  Particle(this.id, {required super.position})
      : super(
          size: Vector2.all(2 * 2.5),
          anchor: Anchor.center,
        );

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

    for (final particle in nearbyParticles) {
      // create an attraction force to each nearby particle.  Do not allow the particles to get too close.
      final distance = (particle.position - position).length;
      final force = _force(distance, 10, 100, 0.1);
      final direction = (particle.position - position).normalized();
      _velocity += direction * force;
    }

    // Update position based on velocity
    position.x += _velocity.x * dt;
    position.y += _velocity.y * dt;

    _establishPositionBounds();
  }

  void _establishPositionBounds() {
    final double maxXPosition = kScreenWidth - radius * 2;
    final double maxYPosition = kSreenHeight - radius * 2;
    final double minXPosition = radius * 2;
    final double minYPosition = radius * 2;

    if (position.x <= minXPosition) {
      position.x = minXPosition;
    }
    if (position.x >= maxXPosition) {
      position.x = maxXPosition;
    }
    if (position.y <= minYPosition) {
      position.y = minYPosition;
    }
    if (position.y >= maxYPosition) {
      position.y = maxYPosition;
    }
  }

  double _force(
      double distance, double rMin, double? rMax, double? attraction) {
    if (distance < rMin) {
      return distance / rMin - 1;
    }

    if (distance < rMax!) {
      return attraction! *
          (1 - (2 * distance - rMin - rMax).abs() / (rMax - rMin));
    }

    return 0;
  }
}

const double kScreenWidth = 800;
const double kSreenHeight = 600;
const kMapBounds = Rect.fromLTRB(
  -kScreenWidth / 2,
  -kSreenHeight / 2,
  kScreenWidth / 2,
  kSreenHeight / 2,
);

class ParticleLifeMap extends Component {
  static final Paint _background = BasicPalette.black.paint();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromLTRB(
        kMapBounds.left,
        kMapBounds.top,
        kMapBounds.right,
        kMapBounds.bottom,
      ),
      _background,
    );
  }
}
