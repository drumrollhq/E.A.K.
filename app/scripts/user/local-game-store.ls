id = (prefix = '') -> "#{prefix}_#{Date.now!}"

module.exports = {
  create: (data) ->
    game-id = id \game
    area-id = id \area
    game = {
      id: game-id
      user-id: data.game.user
      created-at: new Date!
      updated-at: new Date!
      state: {}
      active-area: area-id
    }

    area = {
      id: area-id
      game-id: game-id
      url: data.area.url
      type: data.area.type
      created-at: new Date!
      updated-at: new Date!
      state: {}
      player-x: null
      player-y: null
    }

    Promise.all [@save game, @save area]
      .then -> {game, area}

  save: (data) ->
    key = data.id
    localforage.set-item key, data
}
