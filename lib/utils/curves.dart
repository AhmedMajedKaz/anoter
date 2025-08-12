import 'dart:math';

double quadraticBezierDistanceApprox(
  Point p, // target point
  Point p0, // start
  Point p1, // control
  Point p2, // end
) {
  // Bézier position
  Point bez(double t) {
    double mt = 1 - t;
    double x = mt * mt * p0.x + 2 * mt * t * p1.x + t * t * p2.x;
    double y = mt * mt * p0.y + 2 * mt * t * p1.y + t * t * p2.y;
    return Point(x, y);
  }

  num dist2(Point a, Point b) =>
      (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);

  // Step 1: coarse search
  int samples = 50;
  double bestT = 0;
  num bestD2 = double.infinity;
  for (int i = 0; i <= samples; i++) {
    double t = i / samples;
    num d2 = dist2(bez(t), p);
    if (d2 < bestD2) {
      bestD2 = d2;
      bestT = t;
    }
  }

  // Step 2: refine with binary search-like approach
  double step = 1.0 / samples;
  while (step > 1e-6) {
    bool improved = false;
    for (double offset in [-step, step]) {
      double t = bestT + offset;
      if (t >= 0 && t <= 1) {
        num d2 = dist2(bez(t), p);
        if (d2 < bestD2) {
          bestD2 = d2;
          bestT = t;
          improved = true;
        }
      }
    }
    if (!improved) step /= 2;
  }

  return sqrt(bestD2);
}
