require! {
  'api'
  'lib/channels'
  'user/Game'
}

class User extends Backbone.DeepModel
  initialize: ->
    err, data <~ api.users.me!
    @loaded = true
    if err
      console.error err
      @set 'available' false
      @_loaded!
      return

    @set available: true
    @set device: data.device

    if data.logged-in
      @set-user data.user
    else
      @set logged-in: false

    @_loaded!

  set-user: (user, logged-in = true) ->
    if user.status is 'creating' then channels.page.publish name: 'signupNext'
    @set logged-in: logged-in, user: user

  ensure-loaded: (cb) ->
    if @loaded then cb this
    @[]_waiting[*] = cb

  _loaded: ->
    for cb in @[]_waiting => cb this

  display-name: ->
    user = @get 'user'
    if user.username then "@#{user.username}" else user.first-name

  login: (username, password, cb = -> null) ->
    err, user <~ api.auth.login username, password
    if err
      cb err
    else
      @set-user user.user
      cb!

  logout: ->
    api.auth.logout!
    @set logged-in: false, user: null
    localforage.remove-item 'resume-id'

  get-game: (cb) ->
    <~ @ensure-loaded
    if @current-game then return cb @current-game
    if @get 'loggedIn'
      can-resume <- Game.can-resume!
      if can-resume
        @current-game = Game.resume cb
      else
        has-local <- Game.has-local!
        if has-local
          Game.create-from-local cb
        else
          Game.create cb
    else
      @current-game = Game.init-local cb

module.exports = new User!
