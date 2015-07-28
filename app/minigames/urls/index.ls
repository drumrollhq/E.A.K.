exports, require, module <- require.register 'minigames/urls/index'
module.exports = class URLMiniGame
  ->
    _.mixin this, Backbone.Events
    console.log 'new URLMiniGame', arguments

  load: ->
    console.log \minigame-load arguments

  start: ->
    console.log \minigame-start arguments

  is-editable: -> false

  cleanup: ->
    console.log \minigame-cleanup arguments
