require! {
  'lib/parse'
  'user'
  'ui/SSOView'
}

module.exports = class SignUpView extends SSOView
  initialize: ->
    super!
    @$form = @$ 'form'
    @$first-name = @$ '.first-name'
    @$over-thirteen = @$ '.over-thirteen'

  events:
    'click .sso': 'ssoButtonClick'
    'submit form': 'submit'

  submit: (e) ->
    e.prevent-default!
    data = @$form.serialize-object!
    unless data.first-name.trim!
      return @$first-name.attention-grab!
    unless data.over-thirteen?
      return @$over-thirteen.attention-grab!

    user.set-user {
      first-name: data.first-name
      assume-adult: parse.to-boolean data.over-thirteen
    }, false

    @parent.activate 'signupNext'
