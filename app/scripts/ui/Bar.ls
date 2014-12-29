require! 'lib/channels'

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit

  initialize: ->
    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe ->
      channels.game-commands.publish command: \edit

  edit: (e) ->
    e.prevent-default!
    e.stop-propagation!
    channels.game-commands.publish command: \edit
    e.target.blur!
