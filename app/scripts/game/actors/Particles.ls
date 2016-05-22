require! {
  'game/actors/Actor'
  'lib/channels'
  'game/effects/particles'
  'lib/math/Vector'
}

module.exports = class Particles extends Actor
  @from-el = (el, [effect-name, x, y], offset, save-level, area-view) ->
    layer = el.attr \data-layer or \effects
    new Particles {
      effect-name
      el
      offset
      area-view
      layer
      position:
        x: parse-float x
        y: parse-float y
      store: save-level
    }

  physics: data:
    ignore: true

  initialize: (options) ->
    super options
    @options = options

  load: ->
    @emitter = particles.get-emitter @options.effect-name, @options.offset
    @emitter.load! .then ~>
      @options.area-view.layers[@options.layer].add @emitter
      @frame-sub = channels.post-frame.subscribe ({t}) ~> @step t
      @emitter.emitter = new Vector @options.position .add @options.offset

  step: (t) ->
    @emitter.step t
