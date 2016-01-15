dom = React.DOM

module.exports = React.create-class {
  display-name: \FadeIn

  get-initial-state: -> {
    active: false
  }

  component-will-mount: ->
    @props.wait-for.then ~>
      @set-state active: true

  render: ->
    dom.span class-name: (cx \fade-enter, 'fade-enter-active': @state.active), @props.children
}
