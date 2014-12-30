require! {
  'api'
}

class User extends Backbone.Model
  initialize: ->
    err, data <~ api.users.me!
    if err
      console.error err
      @set 'available' false
    console.log data
    data.available = true
    @set data

  set-user: (user) ->
    @set logged-in: true, user: user

  display-name: ->
    user = @get 'user'
    user.username or user.first-name

  logout: ->
    api.auth.logout!
    @set logged-in: false, user: null

module.exports = new User!
