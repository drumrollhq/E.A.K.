require! {
  'audio/music-manager'
  'game/area/AreaView'
  'game/area/background'
  'game/event-loop'
  'lib/channels'
  'lib/physics'
  'loader/ElementLoader'
  'loader/LoaderView'
}

module.exports = class Area extends Backbone.Model
  initialize: ({conf, @event-id, @prefix, @player-coords}) ->
    @subs = []
    @set conf.{width, height, background, music}
    @view = new AreaView model: this
    @levels = conf.levels

  start: ->
    event-loop.pause!
    <~ @load!
    @view.$el.append-to \#levelcontainer
    @view.render!
    <~ @setup!
    @subscribe!
    event-loop.resume!

  load: (cb) ~>
    @setup-loader!
    err <~ async.parallel [@load-levels, @load-background, @load-music]
    <- @hide-loader!
    cb err

  setup: (cb) ->
    @view.add-levels!
    @view.add-targets!
    <~ @view.setup-sprite-sheets
    @view.create-maps!
    @build-map!
    cb!

  build-map: ->
    nodes = @view.assemble-map!
    nodes[*] = @view.player or @view.add-player @player-coords
    @state = physics.prepare nodes

  subscribe: ->
    @subs[*] = channels.frame.subscribe @frame
    @subs[*] = channels.game-commands.subscribe @game-command

  frame: (data) ~>
    @state = physics.step @state, data.t
    physics.events @state, channels.contact
    @check-player-is-in-world!
    @update-player-level!

  game-command: ({command, payload}) ~>
    | command is 'edit' and @view.is-editable! => @view.start-editor!
    | command is 'stop' => @complete payload

  update-player-level: ->
    l = @view.get-player-level!
    if l? and l isnt @get 'playerLevel'
      @set 'playerLevel', l

  const world-pad = 100
  check-player-is-in-world: !~>
    pos = @view.player.p
    unless (-world-pad < pos.x < world-pad + @get 'width') and (-world-pad < pos.y < world-pad + @get 'height')
      channels.death.publish cause: 'fall-out-of-world'

  load-levels: (cb) ~> async.each @levels, @load-level-source, cb
  load-background: (cb) ~> background.show (@get 'background'), cb
  load-music: (cb) ~> music-manager.start-track (@get 'music'), cb

  setup-loader: ->
    @loader = loader = new ElementLoader el: @view.$el
    @loader-view = loader-view = new LoaderView model: loader
    loader-view.hide-progress!
    loader-view.$el.append-to '#main > .app'
    loader-view.render!

  load-level-source: (level, cb) ~>
    $.ajax "#{@prefix}/#{level.url}?#{Date.now!}", {
      error: (jq, status, err) -> cb err
      success: (src) ->
        [err, $level] = parse-src src
        if err then return cb err

        level.src = src
        level.$el = $level
        cb!
    }

  hide-loader: (cb) ~>
    <~ $.hide-dialogues!
    @loader-view.remove!
    @loader = null
    @loader-view = null
    cb!

  complete: (payload = {handled: false, callback: -> null}) ->
    payload.handled = true
    cb = payload.callback or -> null

    if @stopped then return
    @stopped = true

    @trigger 'done'
    $ document.body .remove-class 'playing hide-bar has-tutorial playing-area'
    @view.remove!
    delete @state
    channels.game-commands.publish command: \level-out
    for sub in @subs => sub.unsubscribe!
    @stop-listening!
    cb!

parse-src = (src) ->
  parsed = Slowparse.HTML document, src, [TreeInspectors.forbidJS]

  if parsed.error
    console.log src, parsed.error
    channels.alert.publish msg: translations.errors.level-errors + "[#{level.url}]"
    return [parsed.error]

  for node in parsed.document.child-nodes
    if typeof! node is 'HTMLHtmlElement' then $level = $ node

  return [null, $level]
