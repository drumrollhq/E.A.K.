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

module.exports = new User!
