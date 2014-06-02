require! {
  'game/physics/collision'
  'game/physics/events'
  'game/physics/Matrix'
  'game/physics/prepare'
  'game/physics/step'
  'game/physics/Vector'
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

    // Triggers events from the state on mediator.
    events state, mediator


*/

module.exports = { Vector, Matrix, prepare, step, collision, events }
