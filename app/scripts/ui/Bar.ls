require! {
  'lib/channels'
  'game/event-loop'
}

module.exports = class Bar extends Backbone.View
  events:
    'click .edit': \edit

  initialize: ->
    channels.key-press.filter ( .key in <[ e i ]> ) .subscribe @start-edit

  edit: (e) ~>
    e.prevent-default!
    e.stop-propagation!
    @start-edit!
    e.target.blur!

  start-edit: ~>
    unless event-loop.paused then channels.game-commands.publish command: \edit
