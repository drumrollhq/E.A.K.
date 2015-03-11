require! {
  'audio/music-manager'
  'game/area/AreaView2'
  'lib/channels'
  'lib/physics'
}

const edit-transition-duration = 500ms

module.exports = class Area
  ({@conf, @prefix, @name, @options}) ->
    _.extend this, Backbone.Events
    for level in @conf.levels => level.url = "#{@name}/#{level.url}"
    @levels = @conf.levels
    @view = new AreaView2 {
      el: $ \#levelcontainer .empty!
      conf: @conf
      options: @options
      prefix: @prefix
    }

  load: ->
    Promise.all [@load-music!, @view.load!]

  start: (stage) ->
    @stage-store = stage
    @view.start stage .then ~>
      @physics-state = physics.prepare @view.build-map!
      @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
      console.log 'ready to go'

  save-defaults: -> {
    type: \area
    url: @name
    state: {}
    levels: @levels.map -> url: it.url, state: {}
  }

  cleanup: ->
    @view.remove!

  on-frame: (t) ->
    @physics-state = physics.step @physics-state, t
    physics.events @physics-state, channels.contact
    @view.step!

  is-editable: ->
    @view.is-editable!

  edit: ->
    @frame-sub.pause!
    @editor = @create-editor @view.player-level
    @view.editor-focus edit-transition-duration

  create-editor: (level) ->
    level.start-editor!

  hide-editor: ->
    @view.editor-unfocus edit-transition-duration
      .then ~>
        console.log \state-before @physics-state
        @physics-state = physics.prepare @view.build-map!
        console.log \state-after @physics-state
        @frame-sub.resume!

  load-music: ->
    music-manager.start-track @conf.music
