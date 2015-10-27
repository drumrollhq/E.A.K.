require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = do
  physics: data:
    dynamic: false
    sensor: true

  initialize: (options) ->
    @render!
    @down-sub = channels.parse 'key-down: j, s, down' .subscribe @activate.bind this
    @down-sub.pause!
    @_down-sub-resume = @down-sub.resume.bind @down-sub
    @_down-sub-pause = @down-sub.pause.bind @down-sub
    @start-activatable-listening!

  start-activatable-listening: ->
    @activatable-listening = true
    @listen-to this, \contact:start:ENTITY_PLAYER, @_down-sub-resume
    @listen-to this, \contact:end:ENTITY_PLAYER, @_down-sub-pause

  stop-activatable-listening: ->
    @activatable-listening = false
    @stop-listening this, \contact:start:ENTITY_PLAYER, @_down-sub-resume
    @stop-listening this, \contact:start:ENTITY_PLAYER, @_down-sub-pause

  render: ->
    @$el.add-class \activatable

  remove: ->
    @down-sub.unsubscribe!
