require! {
  'audio/music-manager'
  'game/area/AreaView'
  'lib/channels'
  'lib/physics'
}

const edit-transition-duration = 500ms

area-scripts = {}

module.exports = class Area
  ({@conf, @prefix, @name, @options}) ->
    _.extend this, Backbone.Events
    area-scripts[@name] ?= []
    for level in @conf.levels => level.url = "#{@name}/#{level.url}"
    @levels = @conf.levels
    @ext = {}
    @view = new AreaView {
      el: $ \#levelcontainer .empty!
      conf: @conf
      options: @options
      prefix: @prefix
      area: this
    }

  load: ->
    Promise.all [@load-music!, @view.load!, @hook \load]

  start: (stage) ->
    @stage-store = stage
    @hook \setup
      .then ~> @view.start stage
      .then ~> @hook \beforeStart
      .then ~>
        @refresh!
        @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
        @hook \start

  save-defaults: -> {
    type: \area
    url: @name
    state: {}
    levels: @levels.map -> url: it.url, state: {}
  }

  cleanup: ->
    @view.remove!
    if @frame-sub then @frame-sub.unsubscribe!
    @hook \cleanup
    @trigger \cleanup

  on-frame: (t) ->
    @physics-state = physics.step @physics-state, t
    physics.events @physics-state, channels.contact
    @view.step!
    unless @_done-after-start
      @hook \afterStart
      @_done-after-start = true

  is-editable: ->
    @view.is-editable!

  edit: ->
    @hook \startEdit
    @frame-sub.pause!
    @editor = @create-editor @view.player-level
    @view.editor-focus edit-transition-duration

  create-editor: (level) ->
    level.start-editor!

  hide-editor: ->
    @view.editor-unfocus edit-transition-duration
      .then ~> @hook \stopEdit
      .then ~>
        @refresh!
        @frame-sub.resume!

  refresh: ->
    @physics-state = physics.prepare @view.build-map!
    @hook \preparePhysics @physics-state

  load-music: ->
    music-manager.start-track @conf.music

  hook: (name, ...args) ->
    hooks = area-scripts[@name]
      .filter (script) ~> script[name]
      .map (script) ~> script[name].apply this, args

    Promise.all hooks

  @register-area-script = (name, script) ->
    hooks = keys script
    console.log "[area] Register #{hooks .join ', '} hooks for #name"
    area-scripts[name] ?= []
    area-scripts[name][*] = script
    script.deregister = ->
      console.log "[area] Deregister #{hooks .join ', '} hooks for #name"
      area-scripts[name] .= filter (isnt script)

    script
