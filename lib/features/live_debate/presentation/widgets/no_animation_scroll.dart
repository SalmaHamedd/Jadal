import 'package:flutter/material.dart';

/// Instantly snaps pages without spring animation (ported from the legacy
/// `InstantSnapScrollPhysics`). Available for paged grid layouts.
class InstantSnapScrollPhysics extends PageScrollPhysics {
  const InstantSnapScrollPhysics({super.parent});

  @override
  InstantSnapScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      InstantSnapScrollPhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final springSim = super.createBallisticSimulation(position, velocity);
    if (springSim is ScrollSpringSimulation) {
      return ClampingScrollSimulation(
        position: springSim.x(double.infinity),
        velocity: 0,
        tolerance: toleranceFor(position),
      );
    }
    return null;
  }
}
