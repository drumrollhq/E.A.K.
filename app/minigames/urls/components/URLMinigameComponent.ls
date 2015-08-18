exports, require, module <- require.register 'minigames/urls/components/URLMinigameComponent'

require! {
  'minigames/urls/components/URLDisplay'
  'minigames/urls/components/HelpfulButtstacks'
}

module.exports = React.create-class {
  display-name: \URLMinigameComponent
  render: ->
    React.DOM.div null,
      React.create-element URLDisplay, ref: \url
      React.create-element HelpfulButtstacks, reg: \help
}
