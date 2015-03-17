require! {
  'game/actors/Actor'
  'lib/channels'
  'game/effects/particles'
  'lib/math/Vector'
}

module.exports = class Particles extends Actor
  @from-el = (el, [effect-name], offset, save-level, area-view) ->
    layer = el.attr \data-layer or \effects
    new Particles {
      effect-name
      el
      offset
      area-view
      layer
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
      console.log eak.view
      @frame-sub = channels.post-frame.subscribe ({t}) ~> @step t

  step: (t) ->
    if eak.view.player?.p? then @emitter.emitter = eak.view.player.p
    @emitter.step t
