exports, require, module <- require.register 'minigames/urls/components/URLEntry'

dom = React.DOM
{CSSTransitionGroup} = React.addons

protocol-sep = /^(:|\/|\\| )+/
normal-sep = /^(\/|\\| )+/
protocol-body = /[^:\/\\ ]+/
normal-body = /[^\/\\ ]+/

transform = Modernizr.prefixed \transform

messages = {
  bad-protocol: 'Woah now! On the web, this part has to be either \'http\' for insecure URLs, or \'https\' for secure ones.'
  spaces: 'You can\'t have spaces in a URL!'
  backslash: 'URLs use forward-slashes \'/\'. You\'ve used backwards-slashes \'\\\' here! GASP.'
  protocol-sep: 'You need a colon and two forward-slashes, like this: \'://\'.'
  multiple-slashes: 'Only on slash, please!'
  sep-default: 'Use one forward-slash \'/\' between each part of your URL.'
}

module.exports = URLEntry = React.create-class {
  display-name: \URLEntry

  statics:
    base-validator: [
      ({token}) ->
        if token.to-lower-case! not in <[http https]>
          messages.bad-protocol

      ({token}) ->
        if token isnt '://'
          if token.match /\s/
            messages.spaces
          else if token.match /\\/
            messages.backslash
          else
            messages.protocol-sep

      ({token, type}) ->
        if type is \sep
          if token isnt '/'
            if token.match /\s/
              messages.spaces
            else if token.match /\\/
              messages.backslash
            else if token.match /\/\//
              messages.multiple-slashes
            else
              messages.sep-default

        else if type is \body
          null
        else throw new TypeError "Unknown type #type"
    ]

  get-initial-state: -> {
    active: false
    current-url: ''
    show-error: false
    error: null
  }

  component-will-update: (_, next-state) ->
    if @state.current-url isnt next-state.current-url
      [@_parsed-url, error] = next-state.current-url
        |> @split-url
        |> @check-url

      clear-timeout @error-timeout
      if error
        @error-timeout = set-timeout (~> @set-state show-error: true, error: error), 2500ms
      else
        @set-state show-error: false

  render: ->
    parts = @_parsed-url or []

    dom.div class-name: \url-entry,
      React.create-element CSSTransitionGroup, transition-name: \url-entry,
        if @state.active then dom.div class-name: \url-entry-box, key: \entry-box,
          dom.input type: \text, value: @state.current-url, ref: \input, on-change: ((e) ~> @set-state current-url: e.target.value)
          dom.div class-name: \url-overlay, ref: \overlay,
            for part, i in parts
              dom.span key: i, ref: part.ref, class-name: (cx \url-segment, "type-#{part.type}", part.{error, last, protocol}),
                part.token

          dom.div class-name: (cx \url-error {active: @state.show-error}), ref: \error,
            @state.error?.error or ''

  component-did-update: ->
    input = @refs.input.get-DOM-node!
    overlay = @refs.overlay.get-DOM-node!
    input.style.min-width = "#{overlay.scroll-width}px"

    if @state.show-error and @refs.error-section
      error = @refs.error.get-DOM-node!
      error-section = @refs.error-section.get-DOM-node!
      error.style[transform] = "translateX(#{error-section.offset-left + error-section.offset-width/2 - 10}px)"

  component-will-unmount: ->
    clear-timeout @error-timeout

  activate: (validator = []) ->
    @set-state active: true
    @validator = validator

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

  check-url: (parts) ~>
    var error-part

    for part, i in parts
      base-validator = URLEntry.base-validator[i] or last URLEntry.base-validator
      validator = @[]validator[i] or last @[]validator or -> null

      error = base-validator part or validator part
      if error
        part.error = error
        if not error-part
          part.ref = \errorSection
          error-part = part

      if i is parts.length - 1 then part.last = true

    [parts, error-part]
}
