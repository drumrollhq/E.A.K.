require! {
  'game/actors/Actor'
  'game/effects/SpriteSet'
}

class TarquinSpaceship extends Actor
  physics: {
    data: dynamic: true
  }

  mapper-ignore: true

  initialize: (start) ->
    super start
    @sprite-set = new SpriteSet {
      main: \relaxed
      sprites:
        relaxed: ['/entities/tarquin-spaceship/sprites/tarquin-relaxed' 110 140 0 0 speed: 15]
        push: ['/entities/tarquin-spaceship/sprites/tarquin-push' 110 140 0.5 -0.5 speed: 15]
        flex-raise: ['/entities/tarquin-spaceship/sprites/tarquin-flex-raise' 110 140 5.5 0 speed: 15]
        flex: ['/entities/tarquin-spaceship/sprites/tarquin-flex' 110 140 6 0 speed: 15]
        flex-lower: ['/entities/tarquin-spaceship/sprites/tarquin-flex-lower' 110 140 5.5 -0.5 speed: 15]
    }

    @sprite-set <<< start.offset.{x, y}
    window.tarquin = @sprite-set

  load: ->
    @sprite-set.load!
      .then ~> @area-view.effects-layer.add @sprite-set

eak.register-actor TarquinSpaceship
