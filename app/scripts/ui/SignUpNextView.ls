require! {
  'api'
  'lib/parse'
  'user'
}

module.exports = class SignUpNextView extends Backbone.View
  initialize: ->
    @$for-adult = @$ '.for-adult'
    @$for-child = @$ '.for-child'
    @$form = @$ 'form'
    @$form-errors = @$ '.form-errors'
    @$form-errors-list = @$ '.form-errors ul'
    @$username-conts = @$ '.username-cont'
    @$username-input = @$ '.username input'
    @$username = @$ '.username .text-field'
    @$password = @$ '.password'
    @$pw = @$ '.pw-initial'
    @$pw-conf = @$ '.pw-confirm'
    @$email = @$ '.email'
    @$gender = @$ '.gender'

    @get-usernames true

    user.on 'change', @render, this
    @render!

  events:
    'click .username-more': 'getUsernames'
    'click .username-cont': 'setUsernameFromEl'
    'submit form': 'submit'

  render: ->
    user-data = user.get 'user'
    unless user-data => return
    if user-data.username then @$username-input.val that

    if user-data.assume-adult
      @$for-adult.remove-class 'hidden'
      @$for-child.add-class 'hidden'
    else
      @$for-adult.add-class 'hidden'
      @$for-child.remove-class 'hidden'

    if user-data.oauths and not empty user-data.oauths
      @$password.add-class 'hidden'
    else
      @$password.remove-class 'hidden'

    if user-data.email and not empty user-data.email.trim!
      @$email.add-class 'hidden'
    else
      @$email.remove-class 'hidden'

    if user-data.gender
      @$gender.add-class 'hidden'
    else
      @$gender.remove-class 'hidden'

  activate: -> @hide-errors!

  submit: (e) ->
    e.prevent-default!
    data = {[key, value.trim!] for key, value of @$form.serialize-object!}
    user-data = user.get 'user'
    unless data.username then return @$username.attention-grab!

    unless user-data.oauths and not empty user-data.oauths
      unless data.password then return @$pw.attention-grab!
      unless data.password-confirm then return @$pw-conf.attention-grab!
      user-data <<< data.{password, password-confirm}

    unless user-data.email and not empty user-data.email
      unless data.email then return @$email.attention-grab!
      user-data.email = data.email

    data.subscribed-newsletter = parse.to-boolean data.subscribed-newsletter
    user-data <<< data.{username, subscribed-newsletter}
    user-data.gender ?= data.gender

    @parent.activate 'signupLoader'
    <~ set-timeout _, 300
    err, user-data <~ api.auth.register user-data
    if err?
      @parent.activate 'signupNext'
      if err.reason is 'Validation error'
        @show-errors err.details
      else
        @show-errors ["Something's gone wrong... #{err.details or err}. That's all we know. Crazy, huh?"]
    else
      user.set-user user-data
      @parent.deactivate!

  get-usernames: (replace-input) ->
    replace-input = replace-input is true
    count = @$username-conts.length
    if replace-input then count += 1

    err, usernames <~ api.users.usernames n: count, unused: true
    if err? then return

    @$username-conts.html (i) -> usernames[i]
    if replace-input then @$username-input.val last usernames

  set-username-from-el: (e) ->
    $el = $ e.target
    @$username-input.val $el.text!

  show-errors: (errs) ->
    @$form-errors-list.empty!
    errs.for-each (err) ~> $ '<li></li>' .text err .append-to @$form-errors-list

    @$form-errors.remove-class 'hidden'

  hide-errors: ->
    @$form-errors.add-class 'hidden'
