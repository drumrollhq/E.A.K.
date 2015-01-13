require! {
  'api'
  'user'
  'ui/SSOView'
}

module.exports = class LoginView extends SSOView
  initialize: ->
    super!

    @$username-field = @$ '.sign-in .username'
    @$password-field = @$ '.sign-in .password'
    @$errors = @$ '.sign-in .form-errors'

  events:
    'click .sso': 'ssoButtonClick'
    'click .sign-up': 'signup'
    'submit': 'submit'

  with-google: -> @sso 'google'
  with-facebook: -> @sso 'facebook'

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
    @$errors
      ..html ''
      ..add-class 'hidden'

  show-error: (msg) ->
    @$errors
      ..html msg
      ..remove-class 'hidden'

  signup: -> @parent.activate 'signup'
