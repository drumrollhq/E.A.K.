exports, require, module <- require.register 'minigames/urls/components/HelpfulButtstacks'

require! {
  'assets'
}

dom = React.DOM

messages = {
  url: 'OK. See the writing at the bottom of the screen? That\'s a URL - the address of where
    in the Internet Universe we\'re heading.'
  domain: 'See where it says \'bulbous-island.com\'? That bit\'s called the domain - for us, it\'s
    the name of the town we\'re trying to get to.'
  move: 'Use the arrow keys to move, and find Bulbous Island'
  wrong-domain: 'Where do ya thing you\'re going? That\'s not Bulbous Island!'
  collect-onions: 'You\'ve found the pickled onions! Press the space key to pick some up'
}

module.exports = React.create-class {
  display-name: \HelpfulButtstacks

  get-initial-state: -> {
    active: false
  }

  render: ->
    dom.div class-name: (cx \helpful-buttstacks, @state.{active}), on-click: (~> @set-state active: not @state.active),
      dom.img src: (assets.load-asset '/minigames/urls/assets/buttstacks.png', \url)
      dom.div class-name: \speech-bubble, 'Hello, world'
}
