import 'dart:collection';

class AverageTracker {
  final _queue = Queue<double>();
  int maxSize;
  double emptyValue;

  AverageTracker(this.maxSize, this.emptyValue);

  void pushValue(double value) {
    _queue.addFirst(value);
    if (_queue.length > maxSize) {
      _queue.removeLast();
    }
  }

  double get average {
    if (_queue.isEmpty) {
      return emptyValue;
    }

    double sum = 0;
    for (var e in _queue) {
      sum += e;
    }
    return sum / _queue.length;
  }
}
