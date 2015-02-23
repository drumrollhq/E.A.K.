id = (prefix = '') -> "#{prefix}_#{Date.now!}_#{_.unique-id!}"

module.exports = {
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

    @save game .then -> {game}

  get: (id) ->
    (Promise.resolve localforage.get-item id)
      .then (game) ->
        Promise.all [
          game
          if game.active-stage then localforage.get-item that
        ]
      .spread (game, active-stage) ->
        game.active-stage = active-stage
        game

  list: ->
    @find {
      where: ( .id.match /game/ )
      sort-by: ( .updated-at )
      limit: 1 # Only one local save-game allowed
      asc: false
    }

  find-or-create-stage: (game-id, stage-data) ->
    game = null
    activate = stage-data.activate or false
    levels = stage-data.levels
    delete stage-data.activate
    delete stage-data.levels

    @get game-id
      .then (game-data) ~>
        game := game-data
        stage-data.game-id = game-id
        @find-one where: (stage) ->
          (stage.id.match /^stage/) and
            stage.{game-id, url, type} === stage-data.{game-id, url, type}
      .catch @LocalNotFoundError, ~>
        stage-data.id = id \stage
        @save stage-data .then -> stage-data
      .then (stage) ~>
        Promise.all [
          stage
          if levels then @find-or-create-levels stage, levels
          if activate then @patch game-id, active-stage: stage.id
        ]
      .spread (stage, levels) ->
        if levels then stage.levels = levels
        stage

  find-or-create-levels: (stage, levels) ->
    Promise.map levels, (level) ~> @find-or-create-level stage, level

  find-or-create-level: (stage, level) ->
    @find-one {
      where: (level) ->
        (level.id.match /^level/) and
          level.{stage-id, url} === {stage-id: stage.id, url: level.url} }
      .catch LocalNotFoundError, ~>
        level.stage-id = stage.id
        level.id = id \level
        @save level .then -> level

  patch: (id, patch) ->
    @get id .then (data) ~>
      data <<< patch
      @save data

  # Save an object, using it's id as the key
  save: (data) ->
    key = data.id
    Promise.resolve localforage.set-item key, data

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
    @find options
      .then ([item]) ~>
        if item
          Promise.resolve item
        else
          Promise.reject new @LocalNotFoundError 'local-game-store item not found'

  LocalNotFoundError: class LocalNotFoundError extends Error
}
