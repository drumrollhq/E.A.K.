require! {
  'api'
  'user'
}

module.exports = class LoginView extends Backbone.View
  initialize: ->
    window.add-event-listener 'message' (e) ~>
      if e.source is @sso-window then @sso-callback e.data

    @$username-field = @$ '.sign-in .username'
    @$password-field = @$ '.sign-in .password'
    @$errors = @$ '.sign-in .form-errors'

  events:
    'click .sso-google': 'withGoogle'
    'click .sso-facebook': 'withFacebook'
    'submit': 'submit'

  with-google: -> @sso 'google'
  with-facebook: -> @sso 'facebook'

  sso: (provider) ->
    if not @sso-window? or @sso-window.closed
      @sso-window = window.open api.auth.url provider, redirect: api.auth.url 'js-return'
      @sso-provider = provider
      console.log @sso-window
    else if @sso-provider is provider
      @sso-window.focus!
    else
      @sso-window.close!
      @sso-provider = @sso-window = null
      @sso provider

  sso-callback: (data) ->
    @sso-window.close!
    window.focus!
    if data.status is 'active'
      user.set-user data
      @trigger 'close'

  activate: ->
    @$username-field.focus!

  submit: (e) ->
    @hide-error!
    if e.prevent-default? then e.prevent-default!
    username = @$username-field.val!
    password = @$password-field.val!
    @$password-field.val ''

    @parent.activate 'loginLoader'
    <~ set-timeout _, 500
    err <~ user.login username, password

    if err?
      @parent.activate 'login'
      @show-error (err.details or err)
    else
      @$username-field.val ''
      @$password-field.val ''
      @parent.deactivate!

  hide-error: ->
    console.log 'hide-err'
    @$errors
      ..html ''
      ..add-class 'hidden'

  show-error: (msg) ->
    console.log 'show-err' msg
    @$errors
      ..html msg
      ..remove-class 'hidden'

