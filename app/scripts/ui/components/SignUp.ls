require! {
  'ui/utils/SSOMixin'
  'ui/utils/error-panel'
  'lib/parse'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \SignUp
  mixins: [Backbone.React.Component.mixin, SSOMixin]

  submit: (e) ->
    e.prevent-default!
    data = $ e.target .serialize-object!
    unless data.first-name.trim!
      return $ @refs.first-name.get-DOM-node! .attention-grab!
    unless data.over-thirteen?
      return $ @refs.over-thirteen.get-DOM-node! .attention-grab!

    @get-model!.set-user {
      first-name: data.first-name
      assume-adult: parse.to-boolean data.over-thirteen
    }, false

    window.location.hash = '/app/signup-next'

  render: ->
    dom.div id: \signup, class-name: 'cont-wide clearfix',
      dom.h2 null, 'Sign Up'
      dom.h3 null, 'What are you into?'
      dom.div class-name: \two-up,
        dom.div class-name: \two-up-col,
          dom.h3 null, 'Social sign-in excitement!?'
          @sso-button \google 'Sign up with Google'
          @sso-button \facebook 'Sign up with Facebook'
        dom.div class-name: \two-up-col,
          dom.h3 null,
            'Or, these crazy text fields?!'
            dom.span class-name: \sub, 'Real talk: they\'re mostly not text fields'
          dom.form on-submit: @submit,
            error-panel @state.error
            dom.label class-name: 'text-field text-field-plain', ref: \firstName,
              dom.span null, 'What\'s your first name?'
              dom.input type: \text, placeholder: 'e.g. Tarquin', required: true, name: \firstName
            dom.label class-name: 'radio-group radio-group-plain over-thirteen', ref: \overThirteen,
              dom.span null, 'Are you aged 13 or over?'
              dom.div class-name: \radio-group-radios,
                dom.input id: \over-13-yes, type: \radio, name: \overThirteen, value: true
                dom.label html-for: \over-13-yes, 'Yes'
                dom.input id: \over-13-no, type: \radio, name: \overThirteen, value: false
                dom.label html-for: \over-13-no, 'No'
            dom.button type: \submit, class-name: 'btn pull-right', 'Onwards! →'
}
