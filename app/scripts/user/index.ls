require! {
  'api'
  'lib/channels'
  'user/Game'
}

class User extends Backbone.DeepModel
  initialize: ->
    @_user-promise = api.users.me!
      .then (data) ~>
        @set available: true
        @set device: data.device

        if data.logged-in then @set-user data.user else @set logged-in: false
      .catch -> console.log 'user error:' arguments

  fetch: ~> @_user-promise

  set-user: (user, logged-in = true) ->
    if user.status is 'creating' then channels.page.publish name: 'signupNext'
    @set logged-in: logged-in, user: user

  display-name: ->
    user = @get 'user'
    if user.username then "@#{user.username}" else user.first-name

  login: (username, password) ->
    api.auth.login username, password
      .then (user) -> @set-user user.user

  logout: ->
    api.auth.logout!
    @set logged-in: false, user: null
    localforage.remove-item 'resume-id'

module.exports = new User!
