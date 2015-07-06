id = (prefix = '') -> "#{prefix}_#{Date.now!}_#{_.unique-id!}"

_tx = {}

module.exports = games = {
  create: (data) ->
    game-id = id \game
    game = {
      id: game-id
      user-id: data.game.user
      created-at: new Date!
      updated-at: new Date!
      state: {}
      active-stage: null
    }

    games.save game .then -> {game}

  get: (id) ->
    (Promise.resolve localforage.get-item id)
      .then (game) ->
        Promise.all [
          game
          if game.active-stage then localforage.get-item that
        ]
      .spread (game, active-stage) ->
        if active-stage then game.active-stage = active-stage
        game

  mine: ->
    games.find {
      where: ( .id.match /game/ )
      sort-by: ( .updated-at )
      limit: 1 # Only one local save-game allowed
      asc: false
    }

  delete: (id) -> ...

  stages:
    find-or-create: (game-id, stage-data) ->
      game = null
      activate = stage-data.activate or false
      levels = stage-data.levels
      delete stage-data.activate
      delete stage-data.levels

      games.get game-id
        .then (game-data) ~>
          game := game-data
          stage-data.game-id = game-id
          games.find-one where: (stage) ->
            (stage.id.match /^stage/) and
              stage.{game-id, url, type} === {game-id, stage-data.url, stage-data.type}
        .catch games.LocalNotFoundError, ~>
          stage-data.id = id \stage
          games.save stage-data .then -> stage-data
        .then (stage) ~>
          Promise.all [
            stage
            if levels then games._find-or-create-levels stage, levels
            if activate then games.patch game-id, active-stage: stage.id
          ]
        .spread (stage, levels) ->
          if levels then stage.levels = levels
          stage

    patch-state: (game-id, stage-id, patch) -> games.patch-state stage-id, patch

  _find-or-create-levels: (stage, levels) ->
    Promise.map levels, (level) ~> games._find-or-create-level stage, level

  _find-or-create-level: (stage, level) ->
    games.find-one {
      where: (doc) ->
        (doc.id.match /^level/) and
          doc.{stage-id, url} === {stage-id: stage.id, url: level.url} }
      .catch LocalNotFoundError, ~>
        level.stage-id = stage.id
        level.id = id \level
        games.save level .then -> level

  levels:
    save-kitten: (game-id, level-id, {kitten}) ->
      Promise.all [
        games._increment-kitten-counter game-id
        games._mark-kitten-saved level-id, kitten
      ]

    patch-state: (game-id, level-id, patch) -> games.patch-state level-id, patch

  _increment-kitten-counter: (game-id) ->
    games.get game-id .then (game) ~>
      game.{}state.kitten-count = if game.state.kitten-count then that + 1 else 1
      games.save game

  _mark-kitten-saved: (level-id, kitten) ->
    games.patch-state level-id, {kittens: "#{kitten}": new Date!}

  patch: (id, patch) ->
    games.tx id, (data) -> _.merge data, patch

  patch-state: (id, patch) ->
    games.tx id, (data) -> data = _.merge data, state: patch

  # Save an object, using it's id as the key
  save: (data) ->
    key = data.id
    if data.active-stage?.id? then data.active-stage = data.active-stage.id
    Promise.resolve localforage.set-item key, data

  tx: (id, fn) ->
    _tx[id] = Promise.resolve _tx[id]
      .then ~> games.get id
      .then fn
      .then (data) ~> games.save data
      .tap ~> _tx[id] = null

  # Find objects from the store that match a certain function.
  # Options:
  #   'where' - a function returning true or false given a document as input
  #   'sort-by' - a function returning a property to sort the documents by - optional
  #   'limit' - an integer stating the maximum number of documents to return - optional
  #   'asc' - boolean - should we sort ascending (true) or descending (false) - optional, default true
  find: (options) ->
    results = []
    Promise.resolve do
      localforage
        .iterate (value) !-> if options.where value then results[*] = value
        .then ->
          if options.sort-by then results := sort-by options.sort-by, results
          if options.asc is false then results := results.reverse!
          if options.limit then results := take options.limit, results
          results

  find-one: (options) ->
    options.limit = 1
    games.find options
      .then ([item]) ~>
        if item
          Promise.resolve item
        else
          Promise.reject new games.LocalNotFoundError 'local-game-store item not found'

  LocalNotFoundError: class LocalNotFoundError extends Error
}
