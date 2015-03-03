require! {
  'audio/music-manager'
  'game/area/AreaView2'
  'lib/channels'
  'lib/physics'
}

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

  is-editable: -> ...
  edit: -> ...
  hide-editor: -> ...

  load-music: ->
    music-manager.start-track @conf.music
