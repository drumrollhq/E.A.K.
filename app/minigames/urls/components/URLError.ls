exports, require, module <- require.register 'minigames/urls/components/URLError'

dom = React.DOM

module.exports = {
  display-name: \URLError

  get-initial-state: -> {
    show: false
  }

  component-did-mount: ->
    @_timer = set-timeout @show, 5000

  render: ->
    dom.div show

  component-will-unmount: ->
    clear-timeout @_timer
}
