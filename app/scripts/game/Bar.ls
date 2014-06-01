require! {
  'channels'
  'game/mediator'
}

module.exports = class Bar extends Backbone.View
  events: do
    'tap .edit': \edit
    'tap .restart': \restart

  initialize: ->
    channels.key-press.filter ( .key is 'e' ) .subscribe -> mediator.trigger 'edit'

  edit: (e) ->
    e.prevent-default!
    e.stop-propagation!
    mediator.trigger \edit
    e.target.blur!

  restart: (e) ->
    e.prevent-default!
    e.stop-propagation!
    mediator.trigger \restart
    e.target.blur!
