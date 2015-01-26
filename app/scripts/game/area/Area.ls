require! {
  'audio/music-manager'
  'game/area/AreaView'
  'game/area/background'
  'game/area/el-modify'
  'game/event-loop'
  'lib/channels'
  'lib/physics'
  'lib/lang/html'
  'loader/ElementLoader'
  'translations'
}

module.exports = class Area extends Backbone.Model
  initialize: ({conf, @event-id, @prefix, @player-coords, @url}) ->
    @subs = []
    @set conf.{width, height, background, music}
    @view = new AreaView model: this
    @levels = conf.levels

  start: ->
    @view.$el.append-to \#levelcontainer
    @view.render!
    @subscribe!
    @view.create-maps!
    @build-map!

  load: ~>
    Promise.all [@load-levels!, @load-background!, @load-music!]
      .then @setup
      .then ~> this

  cleanup: ->
    @complete!

  setup: ~>
    @view.add-levels!
    @view.add-targets!
    @view.add-actors!
    @view.setup-sprite-sheets!

  build-map: ->
    nodes = @view.assemble-map!
    nodes[*] = @view.player or @view.add-player @player-coords
    @state = physics.prepare nodes

  subscribe: ->
    @subs[*] = channels.frame.subscribe @frame

  frame: (data) ~>
    @state = physics.step @state, data.t
    physics.events @state, channels.contact
    @check-player-is-in-world!
    @update-player-level!

  edit: ->
    @view.start-editor!
    @view.once 'stop-editor' ~>
      console.log 'stop-editor'
      @trigger 'stop-editor'

  hide-editor: -> @view.stop-editor!

  is-editable: -> @view.is-editable!

  update-player-level: ->
    l = @view.get-player-level!
    if l? and l isnt @get 'playerLevel'
      @set 'playerLevel', l

  const world-pad = 100
  check-player-is-in-world: !~>
    pos = @view.player.p
    unless (-world-pad < pos.x < world-pad + @get 'width') and (-world-pad < pos.y < world-pad + @get 'height')
      channels.death.publish cause: 'fall-out-of-world'

  load-levels: ~> Promise.map @levels, @load-level-source
  load-background: ~> background.show (@get 'background')
  load-music: ~> music-manager.start-track (@get 'music')

  setup-loader: ->
    @loader = loader = new ElementLoader el: @view.$el
    @loader-view = loader-view = new LoaderView model: loader
    loader-view.hide-progress!
    loader-view.$el.append-to '#main > .app'
    loader-view.render!

  load-level-source: (level) ~>
    Promise.resolve $.ajax "#{@prefix}/areas/#{@url}/#{level.url}?_v=#{EAKVERSION}"
      .then (src) ->
        [err, $level] = parse-src src, level
        if err then throw err
        level.src = src
        level.$el = $level
        level

  complete: ->
    if @stopped then return
    @stopped = true

    @trigger 'done'
    $ document.body .remove-class 'playing hide-bar has-tutorial playing-area'
    @view.remove!
    delete @state
    channels.game-commands.publish command: \level-out
    for sub in @subs => sub.unsubscribe!
    @stop-listening!

parse-src = (src, level) ->
  parsed = html.to-dom src

  if parsed.error
    unless parsed.document.query-selector 'meta[name=glitch]'
      console.log src, parsed.error
      channels.alert.publish msg: translations.errors.level-errors + "[#{level.url}]"
      return [parsed.error]

  for node in parsed.document.child-nodes
    if typeof! node is 'HTMLHtmlElement' then $level = $ node

  $level.source = src
  el-modify $level

  return [null, $level]
