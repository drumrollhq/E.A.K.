module.exports = React.create-class {
  display-name: \NoUISlider

  get-default-props: -> {
    range: min: 0, max: 1
    step: 0.01
    value: 0
  }

  get-initial-state: -> {
    value: @props.value
  }

  component-did-mount: ->
    $el = $ @get-DOM-node!
    $el.no-ui-slider {
      start: @state.value
      range: @props.range
      step: @props.step
    }

    $el.on 'slide set', @change-slider

  change-slider: (e, v) ->
    value = parse-float v
    @props.on-change value

  render: -> React.DOM.div class-name: \slider
}
