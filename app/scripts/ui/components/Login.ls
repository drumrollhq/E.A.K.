require! {
  'ui/utils/SSOMixin'
  'ui/utils/loader'
  'ui/utils/error-panel'
  'user'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \Login
  mixins: [SSOMixin, React.addons.PureRenderMixin]

  get-initial-state: -> {
    username: ''
    password: ''
    error: null
    loading: false
  }

  component-did-mount: ->
    <~ set-timeout _, 100 # Need to let the animation finish
    @refs.username.get-DOM-node!.focus!

  submit: (e) ->
    if e?.prevent-default? then e.prevent-default!

    {username, password} = @state
    @set-state password: '', error: null, loading: true
    Promise.delay 300
      .then ~> user.login username, password
      .then ~>
        @set-state username: '', password: '', error: null, loading: false
        @props.on-close!
      .catch (e) ~>
        console.error e
        @set-state loading: false, error: error-message e

  render: ->
    dom.div class-name: \cont,
      dom.h2 null, 'Sign In'
      loader.toggle @state.loading, 'Signing in...',
        dom.p null,
          'No Account? '
          dom.a href: '#/app/signup' class-name: (cx \sign-up \btn), 'Sign up here.'
          ' Itʼs pretty great.'
        dom.div class-name: \sign-in,
          @sso-button \google 'Sign in with Google'
          @sso-button \facebook 'Sign in with Facebook'
          dom.div class-name: \hr, 'or'
          dom.form class-name: \clearfix, on-submit: @submit,
            error-panel @state.error
            dom.label class-name: \text-field,
              dom.span null, 'Username or email'
              dom.input {
                ref: \username
                type: \text
                class-name: \username
                required: true
                value: @state.username
                on-change: (e) ~> @set-state username: e.target.value
              }
            dom.label class-name: \text-field,
              dom.span null, 'Password'
              dom.input {
                ref: \password
                type: \password
                class-name: \password
                required: true
                value: @state.password
                on-change: (e) ~> @set-state password: e.target.value
              }
            dom.button class-name: (cx \btn \pull-right), type: \submit,
              'Sign In →'
}
