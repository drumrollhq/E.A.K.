exports, require, module <- require.register 'minigames/urls/components/URLEntry'

require! {
  'lib/get-at'
}

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
  multiple-slashes: 'Only one slash, please!'
  sep-default: 'Use one forward-slash \'/\' between each part of your URL.'
  four-oh-four: '404! 404! That means this is an address to somewhere that doesn\'t exist. Try using one of the suggestions that pop up as you type.'
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
    show-error: false
    error: null
    focused: false
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
    suggestions = @suggestions!

    last-part = last parts
    show-suggestions = @state.focused
      and (not empty suggestions)
      and last-part?
      and not (last-part.protocol and last-part.type is \body)

    @_show-suggestions = show-suggestions

    show-last-error = if @state.error?
      if @state.error.last then not @state.focused else true
    else false

    dom.div class-name: \url-entry,
      React.create-element CSSTransitionGroup, transition-name: \url-entry,
        if @state.active then dom.div class-name: \url-entry-box, key: \entry-box,
          dom.input do
            type: \text
            value: @state.current-url
            ref: \input
            on-change: (e) ~> @set-state current-url: e.target.value
            on-focus: ~> @set-state focused: true
            on-blur: ~> @set-state focused: false
            on-key-down: @keydown
          dom.div class-name: \url-overlay, ref: \overlay,
            for part, i in parts
              err = if part.error and part.last
                show-last-error
              else
                part.error
              dom.span key: i, ref: part.ref, class-name: (cx \url-segment, "type-#{part.type}", part.{last, protocol}, error: err),
                part.token

          dom.div class-name: (cx \url-error {active: @state.show-error and not @_show-suggestions and show-last-error}), ref: \error,
            @state.error?.error or ''

          dom.ul class-name: (cx \url-suggestions, active: show-suggestions), ref: \suggestions,
            for let suggestion, i in suggestions
              if suggestion.longest-match
                words = suggestion.word
                  .split suggestion.longest-match
                  .map (word, i, arr) ->
                    if i is arr.length - 1
                      {str: word, dom: dom.span}
                    else
                      [{str: word, dom: dom.span}, {str: suggestion.longest-match, dom: dom.strong}]

                suggestion._word = flatten words
              else
                suggestion._word = [{str: suggestion.word, dom: dom.span}]

              dom.li class-name: \url-suggestion, key: i, on-click: (~> @set-last-section suggestion.word),
                for segment, i in suggestion._word
                  segment.dom key: i, segment.str

          dom.button class-name: (cx 'url-submit btn', active: @state.show-submit), on-click: @submit,
            'Go! →'

  component-did-update: ->
    unless @state.active then return
    input = @refs.input.get-DOM-node!
    overlay = @refs.overlay.get-DOM-node!
    input.style.min-width = "#{overlay.scroll-width}px"

    if @state.show-error and @refs.error-section
      error = @refs.error.get-DOM-node!
      error-section = @refs.error-section.get-DOM-node!
      error.style[transform] = "translateX(#{Math.round error-section.offset-left + error-section.offset-width/2 - 10}px)"

    if @_show-suggestions
      suggestions = @refs.suggestions.get-DOM-node!
      last-section = last overlay.children
      if last-section.class-list.contains \type-sep
        target = last-section.offset-left + last-section.offset-width
      else
        target = last-section.offset-left

      suggestions.style[transform] = "translateX(#{Math.round target - 10}px)"

  component-will-unmount: ->
    clear-timeout @error-timeout

  keydown: (e) ->
    if e.which in [9 13]
      e.prevent-default!
      suggestion = first @suggestions!
      if suggestion and suggestion.score > 0
        @set-last-section suggestion.word

  submit: ->
    [@_parsed-url, error] = @state.current-url
      |> @split-url
      |> @check-url

    clear-timeout @error-timeout
    @set-state show-error: true, error: error

    if @props.on-submit and not error
      @props.on-submit (@format-url @_parsed-url), @_parsed-url

  set-last-section: (section) ->
    url = [] ++ @_parsed-url
    last-section = last url
    if last-section.type is \sep
      url[*] = type: \body, token: section
    else
      last-section.token = section

    url[*] = type: \sep, token: '/'
    @set-state current-url: @format-url url

    @refs.input.get-DOM-node!.focus!

  activate: (start-url) ->
    @set-state active: true, current-url: start-url
    # @validator = validator

  deactivate: ->
    @set-state active: false

  format-url: (url) ->
    url
      .map ( .token )
      .join ''

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

  check-url: (parts) ->
    var error-part

    valid-path = []

    for part, i in parts
      if part.type is \body and not part.protocol
        valid-path[*] = part.token.to-lower-case!

      base-validator = URLEntry.base-validator[i] or last URLEntry.base-validator
      validator = @[]validator[i] or last @[]validator or -> null

      error = base-validator part or validator part

      if not error and not get-at @props.valid-urls, valid-path
        error = messages.four-oh-four

      if error
        part.error = error
        if not error-part
          part.ref = \errorSection
          error-part = part

      if i is parts.length - 1 then part.last = true

    [parts, error-part]

  suggestions: ->
    parts = @_parsed-url or []
    path = parts
      |> filter (part) -> not part.protocol and part.type is \body and not part.last
      |> map ( .token.to-lower-case! )

    last-part = last parts
    if not last-part or last-part.type is \sep
      str = ''
    else
      str = last-part.token

    str-parts = str
      .split ''
      .map (_, i) -> take i + 1, str
      .reverse!

    score = (word) ->
      longest-match = str-parts
        |> find (str-part) -> (word.index-of str-part) isnt -1

      score = longest-match?.length or -1 * word.char-code-at 0

      {word, score, longest-match}

    suggestions = get-at @props.valid-urls, (path or [])
      |> keys
      |> filter ( isnt \_path )
      |> map score
      |> sort-by ( .score )
      |> reverse

    top = first suggestions
    if window.dbg_url then debugger
    if top?
      path = (path or []) ++ [top.word]

    _path = (get-at @props.valid-urls, (path or []) or {})._path
    if top?.score < 3
      _path = (take _path.length - 1, _path) ++ [undefined]

    @props.on-valid-url _path

    suggestions
}
