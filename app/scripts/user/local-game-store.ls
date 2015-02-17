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

  list: ->
    @find {
      where: ( .id.match /game/ )
      sort-by: ( .updated-at )
      limit: 1 # Only one local save-game allowed
      asc: false
    }

  # Save an object, using it's id as the key
  save: (data) ->
    key = data.id
    localforage.set-item key, data

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
}
