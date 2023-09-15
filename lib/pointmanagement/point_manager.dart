import 'package:particle_life_flutter/pointmanagement/point.dart';
import 'package:particle_life_flutter/pointmanagement/point_cluster.dart';

class PointManager {
  List<PointCluster>? clusters;
  int? nx;
  late int ny;
  late num minX;
  late num maxX;
  late num minY;
  late num maxY;

  List<PointCluster>? clusterBuffer;

  PointManager(num minGridSpacing, num particleDensity, this.minX, this.maxX,
      this.minY, this.maxY) {
    nx = ((maxX - minX) / minGridSpacing).floor();
    ny = ((maxY - minY) / minGridSpacing).floor();

    initCluster(
        (10 * particleDensity * minGridSpacing * minGridSpacing).ceil());

    clusterBuffer =
        List.generate(clusters!.length, (_) => PointCluster(), growable: false);
  }

  void initCluster(int initialCapacity) {
    clusters = List.generate(nx! * ny, (_) => PointCluster(), growable: false);
  }

  void add(Point p) {
    clusters![getClusterIndex(p)].add(p);
  }

  int getClusterIndex(Point p) {
    return getClusterIndexFromClusterPos(
        constrain(getClusterX(p.x!), 0, nx! - 1),
        constrain(getClusterY(p.y!), 0, ny - 1));
  }

  int getClusterX(num x) {
    return (nx! * (x - minX) / (maxX - minX)).floor();
  }

  int getClusterY(num y) {
    return (ny * (y - minY) / (maxY - minY)).floor();
  }

  int constrain(int a, int min, int max) {
    if (a < min) {
      return min;
    }
    if (a > max) {
      return max;
    }
    return a;
  }

  int modulo(int a, int b) {
    return ((a % b) + b) % b;
  }

  int getClusterIndexFromClusterPos(int cx, int cy) {
    return cy * nx! + cx;
  }

  List<int> getRelevantClusterIndices(
      final int clusterX, final int clusterY, bool wrapWorld) {
    List<int> relevantClusterIndices = [];

    int minClusterX = clusterX - 1;
    int minClusterY = clusterY - 1;
    int maxClusterX = clusterX + 1;
    int maxClusterY = clusterY + 1;

    if (wrapWorld) {
      for (int cx = minClusterX; cx <= maxClusterX; cx++) {
        for (int cy = minClusterY; cy <= maxClusterY; cy++) {
          relevantClusterIndices.add(
              getClusterIndexFromClusterPos(modulo(cx, nx!), modulo(cy, ny)));
        }
      }
    } else {
      minClusterX = constrain(minClusterX, 0, nx! - 1);
      maxClusterX = constrain(maxClusterX, 0, nx! - 1);
      minClusterY = constrain(minClusterY, 0, ny - 1);
      maxClusterY = constrain(maxClusterY, 0, ny - 1);

      for (int cx = minClusterX; cx <= maxClusterX; cx++) {
        for (int cy = minClusterY; cy <= maxClusterY; cy++) {
          relevantClusterIndices.add(getClusterIndexFromClusterPos(cx, cy));
        }
      }
    }

    return relevantClusterIndices;
  }

  AllIterator getAllWithRelevant(bool wrapWorld) {
    return AllIterator(this, wrapWorld, true);
  }

  AllIterator getAll() {
    return AllIterator(this, false, false);
  }

  List<Point> getRelevant(num x, num y, bool wrapWorld) {
    List<Point> points = [];
    final indices =
        getRelevantClusterIndices(getClusterX(x), getClusterY(y), wrapWorld);
    for (int index in indices) {
      for (var point in clusters![index].getPointsInside()!) {
        points.add(point);
      }
    }
    return points;
  }

  void recalculate() {
    for (PointCluster pointCluster in clusterBuffer!) {
      pointCluster.clear();
    }

    for (int clusterIndex = 0;
        clusterIndex < clusters!.length;
        clusterIndex++) {
      PointCluster cluster = clusters![clusterIndex];

      Iterator<Point> iterator = cluster.getPointsInside()!.iterator;
      while (iterator.moveNext()) {
        clusterBuffer![getClusterIndex(iterator.current)].add(iterator.current);
      }
    }

    // swap buffers
    List<PointCluster>? oldClusters = clusters;
    clusters = clusterBuffer;
    clusterBuffer = oldClusters;
  }

  void clear() {
    for (PointCluster cluster in clusters!) {
      cluster.clear();
    }
  }
}

class AllIterator implements Iterator<Point> {
  int clusterX = 0;
  int clusterY = 0;
  int clusterIndex = 0;

  late Iterator<Point> insidePoints;
  late bool wrapWorld;
  late bool computeRelevant;

  List<Point> relevantPoints = [];

  late PointManager pointManager;

  AllIterator(this.pointManager, this.wrapWorld, this.computeRelevant) {
    insidePoints =
        pointManager.clusters![clusterIndex].getPointsInside()!.iterator;
  }

  void increment() {
    clusterX++;
    if (clusterX == pointManager.nx) {
      clusterX = 0;
      clusterY++;
    }
    clusterIndex++;
  }

  List<Point> getRelevant() {
    return relevantPoints;
  }

  @override
  Point get current => insidePoints.current;

  @override
  bool moveNext() {
    while (!insidePoints.moveNext()) {
      increment();

      if (clusterIndex >= pointManager.clusters!.length) {
        return false;
      }

      insidePoints =
          pointManager.clusters![clusterIndex].getPointsInside()!.iterator;
    }

    if (computeRelevant) {
      relevantPoints.clear();
      final indices =
          pointManager.getRelevantClusterIndices(clusterX, clusterY, wrapWorld);

      for (int index in indices) {
        for (var point in pointManager.clusters![index].getPointsInside()!) {
          relevantPoints.add(point);
        }
      }
    }

    return true;
  }
}
