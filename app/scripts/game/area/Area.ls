require! {
  'audio/music-manager'
  'game/area/AreaView'
  'lib/channels'
  'lib/physics'
}

const edit-transition-duration = 500ms

module.exports = class Area
  ({@conf, @prefix, @name, @options}) ->
    _.extend this, Backbone.Events
    for level in @conf.levels => level.url = "#{@name}/#{level.url}"
    @levels = @conf.levels
    @view = new AreaView {
      el: $ \#levelcontainer .empty!
      conf: @conf
      options: @options
      prefix: @prefix
      area: this
    }

  load: ->
    Promise.all [@load-music!, @view.load!]

  start: (stage) ->
    @stage-store = stage
    @view.start stage .then ~>
      @physics-state = physics.prepare @view.build-map!
      @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
      @trigger \start

  save-defaults: -> {
    type: \area
    url: @name
    state: {}
    levels: @levels.map -> url: it.url, state: {}
  }

  cleanup: ->
    @trigger \cleanup
    @view.remove!
    if @frame-sub then @frame-sub.unsubscribe!

  on-frame: (t) ->
    @physics-state = physics.step @physics-state, t
    physics.events @physics-state, channels.contact
    @view.step!

  is-editable: ->
    @view.is-editable!

  edit: ->
    @trigger \before-edit
    @frame-sub.pause!
    @editor = @create-editor @view.player-level
    @view.editor-focus edit-transition-duration
      .tap ~> @trigger \edit, @editor

  create-editor: (level) ->
    level.start-editor!

  hide-editor: ->
    @trigger \before-finish-edit, @editor
    @view.editor-unfocus edit-transition-duration
      .then ~>
        @physics-state = physics.prepare @view.build-map!
        @frame-sub.resume!
        @trigger \finish-edit

  load-music: ->
    music-manager.start-track @conf.music

  find: (selector) ->
    first @find-all selector

  find-all: (selector) ->
    @physics-state.nodes.filter ({ids}) -> selector in ids
