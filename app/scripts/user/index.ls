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
    @set logged-in: logged-in, user: user

  display-name: ->
    user = @get 'user'
    if user.username then "@#{user.username}" else user.first-name

  login: (username, password) ->
    api.auth.login username, password
      .then (user) ~> @set-user user.user

  logout: ->
    api.auth.logout!
    @set logged-in: false, user: null
    localforage.remove-item 'resume-id'

  new-game: (options) ->
    Game.new store: game-store!, user: (@get \user), options: options
      .tap (game) ~> @game = game

  recent-games: (limit = 10) ->
    game-store!
      .list {limit}
      .then (games) ->
        new SaveGames games

module.exports = new User!
