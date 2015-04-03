require! {
  'api'
  'lib/channels'
  'user/Game'
  'user/SaveGames'
  'user/game-store'
}

class User extends Backbone.DeepModel
  initialize: ->
    @_user-promise = api.users.me!
      .then (data) ~>
        @set available: true
        @set device: data.device

        if data.logged-in then @set-user data.user else @set logged-in: false
      .catch (xhr) ~>
        @set available: xhr.status is 401
        @set-user null, false
        null

  fetch: ~> @_user-promise

  logged-in: ~> @get \loggedIn

  set-user: (user, logged-in = true) ->
    if user?.status is 'creating' then channels.page.publish name: 'signupNext'
    @set logged-in: logged-in, user: user, id: user?.id

  display-name: ->
    user = @get 'user'
    if user.first-name then user.first-name else "@#{user.username}"

  login: (username, password) ->
    api.auth.login username, password
      .then (user) ~> @set-user user.user

  logout: ->
    api.auth.logout!
    @set logged-in: false, user: null
    localforage.remove-item 'resume-id'

  new-game: (stage-defaults) ->
    Game.new store: game-store!, user: (@get \user), stage-defaults: stage-defaults
      .tap (game) ~> @game = game

  load-game: (game) ->
    Game.load store: game-store!, user: (@get \user), id: game.id || game
      .tap (game) ~> @game = game

  recent-games: (limit = 10) ->
    game-store!
      .list {limit}
      .then (games) ~>
        new SaveGames games, user: this

module.exports = new User!
