exports, require, module <- require.register 'minigames/urls/index'

require! {
  'lib/channels'
  'minigames/urls/URLMiniGameView'
}

module.exports = class URLMiniGame
  ->
    _.mixin this, Backbone.Events
    @view = new URLMiniGameView el: ($ \#levelcontainer .empty!)

  load: ->
    @view.load!

  start: ->
    @view.start!
    @view.set-target-url 'http', 'bulbous-island.com', 'onions-r-us', 'pickled-onions'
    @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t

  on-frame: (t) ->
    @view.step t

  is-editable: -> false

  cleanup: ->
    console.log \minigame-cleanup arguments
