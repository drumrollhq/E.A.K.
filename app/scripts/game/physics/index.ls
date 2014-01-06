require! {
  './Vector'
  './Matrix'
  './collision'
  './prepare'
  './step'
}

/*

A modular physics library for use with maps from game/dom/mapper.

Usage:

  map = get-map-from-mapper!

  // state represents the entire physics world
  state = prepare map

  every frame:
    // Update runs the physics simulations to get to the next frame. time-delta should be the
    // number of milliseconds elapsed since the last frame
    state = step state, time-delta


*/

module.exports = { Vector, Matrix, prepare, step, collision }
