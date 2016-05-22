exports, require, module <- require.register 'minigames/urls/components/URLMinigameComponent'

require! {
  'minigames/urls/components/URLDisplay'
  'minigames/urls/components/URLEntry'
  'minigames/urls/components/HelpfulButtstacks'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \URLMinigameComponent

  get-initial-state: -> {
    target-img: null
    correct: false
  }

  render: ->
    dom.div null,
      React.create-element URLDisplay, ref: \url, on-correct: @props.on-correct, on-incorrect: @props.on-incorrect
      React.create-element URLEntry, ref: \urlEntry, valid-urls: @props.valid-urls, on-valid-url: @props.on-valid-url, on-submit: @props.on-submit
      React.create-element HelpfulButtstacks, ref: \help
      dom.div class-name: (cx \target-image, hidden: not @state.target-img, correct: @state.correct),
        dom.img src: @state.target-img
}
