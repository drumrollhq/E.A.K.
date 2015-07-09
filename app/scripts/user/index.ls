require! {
  'hindquarters'
  'lib/channels'
  'user/Game'
  'user/SaveGames'
  'user/game-store'
}

class User extends Backbone.DeepModel
  initialize: ->
    @_user-promise = hindquarters.users.current!
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

  full-name: ->
    user = @get \user
    "#{capitalize user.first-name or ''} #{capitalize user.last-name or ''}".trim!

  login: (username, password) ->
    hindquarters.auth.login {username, password}
      .then (user) ~> @set-user user.user

  logout: ->
    hindquarters.auth.logout!
    @set logged-in: false, user: null
    localforage.remove-item 'resume-id'

  subscribe: (body) ->
    hindquarters.users.subscribe (@get \user.id), body

  new-game: (stage-defaults) ->
    Game.new store: game-store!, user: (@get \user), stage-defaults: stage-defaults
      .tap (game) ~> @game = game

  load-game: (game) ->
    Game.load store: game-store!, user: (@get \user), id: game.id || game
      .tap (game) ~> @game = game

  recent-games: (limit = 10) ->
    game-store!
      .mine {limit}
      .then (games) ->
        new SaveGames games

module.exports = new User!
