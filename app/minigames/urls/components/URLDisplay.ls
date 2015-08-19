exports, require, module <- require.register 'minigames/urls/components/URLDisplay'

dom = React.DOM
{CSSTransitionGroup} = React.addons

module.exports = React.create-class {
  display-name: \URLDisplay

  get-initial-state: -> {
    target: []
    actual: []
    correct: false
    hidden: true
  }

  fmt-url: ([protocol, domain, ...path]) ->
    "#{protocol}://#{domain}/#{path.join '/'}"

  render: ->
    parts = for i til Math.max @state.actual.length, @state.target.length
      [@state.actual[i], @state.target[i] or false]

    parts = flatten parts.map ([actual, target], i) ->
      correct = actual is target
      has-alternative = actual? and target?

      main = dom.div class-name: (cx \url-section, {has-alternative, correct, target-empty: target is false}), key: "section-#i",
        React.create-element CSSTransitionGroup, transition-name: 'url-section', [
          if correct and has-alternative
            dom.div class-name: \url-tick, key: \tick, '✓'
          else if has-alternative
            dom.div class-name: \url-alt, key: "alt-#actual", actual

          (dom.div {
            class-name: (cx \url-section-target {correct, incorrect: has-alternative and not correct})
            key: (if has-alternative and not correct then \target-incorrect else \target)
          }, (target or ''))
        ]

      sep = dom.div class-name: \url-sep, key: "sep-#i", if i is 0
        '://'
      else if i is 1 or i isnt parts.length - 1
        '/'
      else ''

      [main, sep]

    dom.div class-name: \url-display,
      dom.div class-name: (cx \url-display-bar, correct: @state.correct, 'url-hide': @state.hidden),
        React.create-element CSSTransitionGroup, transition-name: 'fade'
          parts

  component-did-update: (_, prev-state) ->
    prev-correct = prev-state.target === prev-state.actual
    correct = @state.target === @state.actual
    if prev-correct and not correct
      if @props.on-incorrect then that!
    else if not prev-correct and correct
      if @props.on-correct then that!
}
