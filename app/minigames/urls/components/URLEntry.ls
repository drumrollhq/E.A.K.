
exports, require, module <- require.register 'minigames/urls/components/URLEntry'

dom = React.DOM
{CSSTransitionGroup} = React.addons

colors = <[red lime blue cyan magenta yellow]>

protocol-sep = /^(:|\/|\\| )+/
normal-sep = /^(\/|\\| )+/
protocol-body = /[^:\/\\ ]+/
normal-body = /[^\/\\ ]+/

module.exports = React.create-class {
  display-name: \URLEntry

  get-initial-state: -> {
    active: false
    current-url: 'hello/world'
  }

  activate: (spec) ->
    @set-state active: true

  deactivate: ->
    @set-state active: false

  split-url: (url) ->
    parts = []

    while url.length > 0
      if parts.length >= 2
        sep = normal-sep
        body = normal-body
        protocol = false
      else
        sep = protocol-sep
        body = protocol-body
        protocol = true

      if url.match sep
        url .= replace sep, (token) ->
          parts[*] = {token, protocol, type: \sep}
          ''
      else if url.match body
        url .= replace body, (token) ->
          parts[*] = {token, protocol, type: \body}
          ''
      else
        break

    parts

  render: ->
    parts = @state.current-url
      |> @split-url

    console.log parts
    dom.div class-name: \url-entry,
      React.create-element CSSTransitionGroup, transition-name: \url-entry,
        if @state.active then dom.div class-name: \url-entry-box, key: \entry-box,
          dom.input type: \text, value: @state.current-url, ref: \input, on-change: ((e) ~> @set-state current-url: e.target.value)
          dom.div class-name: \url-overlay, ref: \overlay,
            for part, i in parts
              dom.span key: i, style: color: colors[i % colors.length],
                part.token

  component-did-update: ->
    input = @refs.input.get-DOM-node!
    overlay = @refs.overlay.get-DOM-node!
    input.style.min-width = "#{overlay.scroll-width}px"
}
