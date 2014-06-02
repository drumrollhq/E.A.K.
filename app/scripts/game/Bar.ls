require! 'channels'

module.exports = class Bar extends Backbone.View
  events: do
    'tap .edit': \edit
    'tap .restart': \restart

  initialize: ->
    channels.key-press.filter ( .key is 'e' ) .subscribe ->
      channels.game-commands.publish command: \edit

  edit: (e) ->
    e.prevent-default!
    e.stop-propagation!
    channels.game-commands.publish command: \edit
    e.target.blur!

  restart: (e) ->
    e.prevent-default!
    e.stop-propagation!
    channels.game-commands.publish command: \restart
    e.target.blur!
