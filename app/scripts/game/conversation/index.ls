require! {
  'audio/tracks'
  'assets'
  'game/conversation/Oulipo'
  'game/conversation/State'
  'game/conversation/components/Conversation': ConversationComponent
  'user'
}

noop-resolve = (v) -> v
noop-reject = (e) -> throw e

export start = (name, $el, {resolve = noop-resolve, reject = noop-reject} = {}) ->
  {nodes, start} = assets.load-asset "#{name}.oulipo.json"

  game-id = user.game.get \game.id
  stage-id = user.game.get \stage.id
  state = new State {
    game: user.game.get \game.state
    stage: user.game.get \stage.state
    lines: []
    view: {}
  }

  update-game = _.debounce do
    (_, update) -> user.game.store.patch-state game-id, update
    500

  update-stage = _.debounce do
    (_, update) -> user.game.store.stages.patch-state game-id, stage-id, update
    500

  state.on \change:game.* update-game
  state.on \change:stage.* update-stage

  conversation = new Oulipo start, nodes, state

  component = React.render (React.create-element ConversationComponent, {model: state}), $el.get 0
  conversation.on \choice, component.choice
  tracks.focus \conversation
  Promise.delay 500
    .cancellable!
    .then -> conversation.start!
    .then resolve
    .catch reject
    .finally ->
      tracks.blur!
      conversation.off \choice component.choice
      state.off \change:game.* update-game
      state.off \change:stage.* update-stage
      React.unmount-component-at-node $el.get 0
