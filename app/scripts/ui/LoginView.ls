require! {
  'ui/templates/login': template
  'user'
  'ui/SSOView'
}

module.exports = class LoginView extends SSOView
  initialize: ->
    super!
    @render!

    @$username-field = @$ '.sign-in .username'
    @$password-field = @$ '.sign-in .password'
    @$errors = @$ '.sign-in .form-errors'

  events:
    'click .sso': 'ssoButtonClick'
    'click .sign-up': 'signup'
    'submit': 'submit'

  render: ->
    @$el.html template!

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
    Promise.delay 300
      .then ~> user.login username, password
      .then ~>
        @$username-field.val ''
        @$password-field.val ''
        @trigger \close
      .catch (err) ~>
        console.error err
        @parent.activate 'login'
        @show-error error-message err

  hide-error: ->
    @$errors
      ..html ''
      ..add-class 'hidden'

  show-error: (msg) ->
    @$errors
      ..html msg
      ..remove-class 'hidden'

  signup: -> @parent.activate 'signup'
