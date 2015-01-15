require! {
  'api'
  'user'
}

module.exports = class Game extends Backbone.DeepModel
  url: -> api.games.url @id

  @can-resume = (cb) ->
    err, id <- localforage.get-item \resume-id
    if err then return cb null
    cb id?

  @has-local = (cb) ->
    err, data <- localforage.get-item \autosave
    if err then return cb null
    cb data?

  @create = (cb) ->
    game = new Game!
    do ->
      err, data <~ api.games.create {}
      if err? then return user.current-game = Game.init-local cb
      game.set data
      game.change-id data.id
      cb game

    return game

  @resume = (cb) ->
    game = new Game!
    do ->
      err, id <~ localforage.get-item \resume-id
      if err then user.current-game = Game.init-local cb
      err, data <~ api.games.get id
      if err then return user.current-game = Game.init-local cb
      game.set data
      game.change-id data.id
      cb game

    return game

  change-id: (id) ->
    @set 'id' id
    @id = id
    localforage.set-item \resume-id id
