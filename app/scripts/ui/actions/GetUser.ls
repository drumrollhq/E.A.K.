require! {
  'user'
  'ui/actions/Action'
}

module.exports = class GetUser extends Action
  initialize: ({@prevent-close = false}) ->
    if user.logged-in! then return @resolve user
    window.location.hash = '/app/login'
    @listen-to user, \change:loggedIn, @user-change

  dismiss: ->
    @cancel!

  user-change: (user, logged-in) ->
    if @prevent-close then @app.bar.prevent-close!
    if logged-in then @resolve user else @cancel!
