require! {
  'api'
  'lib/channels'
}

class User extends Backbone.Model
  initialize: ->
    err, data <~ api.users.me!
    if err
      console.error err
      @set 'available' false
      return

    @set available: true
    @set device: data.device

    if data.logged-in
      @set-user data.user
    else
      @set logged-in: false

  set-user: (user, logged-in = true) ->
    console.log 'set-user' user
    if user.status is 'creating' then channels.page.publish name: 'signupNext'
    @set logged-in: logged-in, user: user

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

module.exports = new User!
