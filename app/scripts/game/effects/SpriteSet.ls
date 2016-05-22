require! {
  'game/effects/SpriteSheet'
}

module.exports = class SpriteSet extends PIXI.Container
  ({@main, sprites, @animations}) ->
    super!

    @sprites = sprites
      |> Obj.map ([url, width, height, x, y, options]) -> new SpriteSheet url, width, height, x, y, options

    for let id, sprite of @sprites => sprite.options.state = \paused

    @sprites[@main].options.state = 'playing'
    @sprites[@main].visible = true
    @currently-playing = @main
    @_queue = []

  load: ->
    Promise.each (keys @sprites), (id) ~>
      sprite = @sprites[id]
      sprite.load!
        .then ~>
          @add-child sprite
          sprite.visible = false unless id is @currently-playing
          sprite.play! if id is @currently-playing
          sprite.on \complete, @on-complete if id is @currently-playing

  on-complete: (stop) ~>
    if @_queue.length > 0
      next = @_queue.shift!
      if typeof next is \function
        next!
        return @on-complete stop

      if next isnt @currently-playing
        stop!
        @switch-to next
    else if @currently-playing isnt @main
      stop!
      @switch-to @main

  switch-to: (name) ->
    if @currently-playing is name then return
    @sprites[@currently-playing]
      ..visible = false
      ..stop!

    @sprites[name]
      ..visible = true
      ..goto-and-play 0

    @sprites[@currently-playing].off \complete, @on-complete
    @sprites[name].on \complete, @on-complete
    @currently-playing = name


  queue: (...items) ->
    for item in items => @_queue[*] = item
    new Promise (resolve) ~>
      @_queue[*] = resolve
