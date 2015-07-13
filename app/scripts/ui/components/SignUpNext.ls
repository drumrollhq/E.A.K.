require! {
  'hindquarters'
  'lib/parse'
  'ui/utils/error-panel-list'
  'ui/utils/loader'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \SignUpNext
  mixins: [Backbone.React.Component.mixin]

  get-initial-state: -> {
    loading: false
    username-suggestions: []
    loading-usernames: true
  }

  component-will-mount: ->
    @fetch-usernames!

  activate: ->
    <~ set-timeout _, 0
    console.log \activate \SignUpNext @state.model.user
    unless @state.model.user?.first-name? and @state.model.user?.assume-adult?
      window.location.hash = '/app/signup'

  fetch-usernames: ->
    @set-state loading-usernames: true
    hindquarters.users.generate-usernames n: 3, unused: true
      .then (usernames) ~>
        @set-state loading-usernames: false, username-suggestions: usernames
      .catch (e) ~>
        @set-state loading-usernames: false
        console.log e
        alert 'Couldn\'t load usernames'

  adult-child: (adult, child) -> if @state.model.{}user.assume-adult then adult else child

  format-username: (username) ->
    username.replace /[^a-zA-Z0-9_]/ '' .slice 0 18

  submit: (e) ->
    e.prevent-default!
    data = {[key, value.trim!] for key, value of $ @refs.form.get-DOM-node! .serialize-object!}
    user-data = {} <<< @get-model!.get \user

    unless data.username then return $ @refs.username.get-DOM-node! .attention-grab!
    unless user-data.oauths and not empty user-data.oauths
      unless data.password then return $ @refs.pw-initial.get-DOM-node! .attention-grab!
      unless data.password-confirm then return $ @refs.pw-confirm.get-DOM-node! .attention-grab!
      user-data <<< data.{password, password-confirm}

    unless user-data.email and not empty user-data.email
      unless data.email then return $ @refs.email.get-DOM-node! .attention-grab!

    if data.email then user-data.email = data.email

    data.subscribed-newsletter = parse.to-boolean data.subscribed-newsletter || \false
    user-data <<< data.{username, subscribed-newsletter}
    user-data.gender ?= data.gender

    @set-state loading: true, errors: []
    Promise.delay 200
      .then ~> hindquarters.auth.register user-data
      .then (user-data) ~>
        @get-model!.set-user user-data
        @set-state loading: false
        @props.on-close!
      .catch (err) ~>
        if err.reason is 'Validation error'
          @set-state loading: false, errors: err.details
        else
          @set-state loading: false, errors: ["#{error-message err}. That's all we know. Crazy, huh?"]

  render: ->
    user = @state.model.user or {}
    dom.div id: \signup-next, class-name: 'cont-wide clearfix',
      dom.h2 null 'Sign Up'
      loader.toggle @state.loading, 'Signing Up...',
        dom.form on-submit: @submit, ref: \form,
          dom.h3 null, 'Surprise! Have some more bits to fill out:'
          error-panel-list 'Ugh. There\'s some crazy sign-up form drama going on right now:', @state.errors
          dom.div class-name: \two-up,
            dom.div class-name: \two-up-col,
              dom.div ref: \username,
                dom.label class-name: 'text-field text-field-plain',
                  dom.span null, 'Pick a username'
                  dom.input {
                    type: \text
                    value: user.username
                    name: \username
                    on-change: (e) ~> @get-model!.set \user.username, @format-username e.target.value
                  }
                dom.span null, 'Or, pick one of these:'
                dom.ul class-name: 'button-list button-list-little',
                  @state.username-suggestions.map (username, i) ~> dom.li key: i,
                    dom.button {
                      type: \button
                      class-name: 'btn username-cont'
                      on-click: ~> @get-model!.set \user.username, username
                    }, username
                  dom.li null,
                    dom.button {
                      type: \button
                      class-name: 'btn username-more'
                      disabled: @state.loading-usernames
                      on-click: @fetch-usernames
                    }, if @state.loading-usernames then 'Loading...' else 'Get more...'
              dom.div class-name: (cx \password \clear hidden: (user.oauths and not empty user.oauths)),
                dom.label class-name: 'text-field text-field-plain', ref: \pwInitial,
                  dom.span null, 'Choose a password:'
                  dom.input type: \password, name: \password
                dom.label class-name: 'text-field text-field-plain', ref: \pwConfirm,
                  dom.span null, 'Confirm the password. I dare you.'
                  dom.input type: \password, name: \passwordConfirm
            dom.div class-name: \two-up-col,
              dom.label class-name: (cx \text-field \email \text-field-plain hidden: user.email?), ref: \email,
                dom.span null,
                  @adult-child 'Please enter your email:', 'Please enter your parent\'s email:'
                dom.input type: \text, name: \email
                dom.span class-name: \sub,
                  @adult-child 'We won\'t send you spam, or share your email with anyone else :)',
                    'We won\'t send them spam, or share thier email with anyone else :)'
              dom.div class-name: (cx \radio-group \radio-group-plain hidden: user.gender?), ref: \gender,
                dom.span null, 'Genders! Yay! Any of these you?'
                dom.div class-name: \radio-group-radios,
                  dom.input id: \gender-male, type: \radio, name: \gender, value: \male
                  dom.label html-for: \gender-male, 'Boy'
                  dom.input id: \gender-female, type: \radio, name: \gender, value: \female
                  dom.label html-for: \gender-female, 'Girl'
                  dom.input id: \gender-nope, type: \radio, name: \gender, value: \nope
                  dom.label html-for: \gender-nope, 'Nope'
              dom.div class-name: 'radio-group radio-group-plain subscribe', ref: \subscribe,
                dom.span null, 'Would you like to recieve infrequent updates about E.A.K?'
                dom.div class-name: \radio-group-radios,
                  dom.input id: \sub-yes, type: \radio, name: \subscribedNewsletter, value: \true
                  dom.label html-for: \sub-yes, 'Yes'
                  dom.input id: \sub-no, type: \radio, name: \subscribedNewsletter, value: \false
                  dom.label html-for: \sub-no, 'No'
              dom.button class-name: 'btn btn-block btn-finish', 'Finish'
}
