require! {
  'assets'
  'game/conversation/Oulipo'
  'game/conversation/State'
  'game/conversation/components/Conversation': ConversationComponent
  'user'
}

export start = (name, $el) ->
  {nodes, start} = assets.load-asset "/#{EAK_LANG}/areas/#{name}.oulipo.json"

  game-id = user.game.get \game.id
  stage-id = user.game.get \stage.id
  state = new State {
    game: user.game.get \game.state
    stage: user.game.get \stage.state
    lines: []
    view: {}
  }

  update-game = _.debounce do
    (update) -> user.game.store.patch-state game-id, update
    500

  update-stage = _.debounce do
    (update) -> user.game.store.stages.patch-state game-id, stage-id, update
    500

  state.on \change:game.* (model, update) ->
    update-game update

  state.on \change:stage.* (model, update) ->
    update-stage update

  conversation = new Oulipo start, nodes, state

  component = React.render (React.create-element ConversationComponent, {model: state}), $el.get 0
  conversation.on \choice, component.choice
  Promise.delay 500
    .then -> conversation.start!
