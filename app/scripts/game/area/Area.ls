require! {
  'game/area/AreaView'
  'loader/ElementLoader'
  'loader/LoaderView'
  'game/level/background'
  'audio/music-manager'
}

module.exports = class Area extends Backbone.Model
  initialize: ({conf, @event-id, @prefix}) ->
    @set conf.{width, height, background, music}
    @view = new AreaView model: this
    @levels = conf.levels

  start: ->
    <~ @load!
    @view.$el.append-to \#levelcontainer
    @view.render!

  load: (cb) ~>
    @setup-loader!
    err <~ async.parallel [@load-levels, @load-background, @load-music]
    <- @hide-loader!
    cb err

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

parse-src = (src) ->
  parsed = Slowparse.HTML document, src, [TreeInspectors.forbidJS]

  if parsed.error
    console.log src, parsed.error
    console.log translations
    channels.alert.publish msg: translations.errors.level-errors + "[#{level.url}]"
    return [parsed.error]

  for node in parsed.document.child-nodes
    if typeof! node is 'HTMLHtmlElement' then $level = $ node

  return [null, @level]
