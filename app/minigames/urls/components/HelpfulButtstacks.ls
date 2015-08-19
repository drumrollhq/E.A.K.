exports, require, module <- require.register 'minigames/urls/components/HelpfulButtstacks'

require! {
  'assets'
}

dom = React.DOM

messages = {
  url: 'OK. See the writing at the bottom of the screen? That\'s a URL - the address of where in the Internet Universe we\'re heading.'
  domain: 'See where it says \'bulbous-island.com\'? That bit\'s called the domain - for us, it\'s the name of the town we\'re trying to get to.'
  move: 'Use the arrow keys to move. Try to find Bulbous Island, like it says on the domain.'
  wrong-domain: 'Where do ya thing you\'re going? That\'s not Bulbous Island!'
  bulbous: 'MMMMmmm! You can just smell those onions. Beautiful. See how the domain in the URL has a tick above it? That means it\'s time to move to the next part of URL - called the path. Try to find Onions-R-Us.'
  bulbous-zoom-out: 'Where ya going? You can\'t be leaving Bulbous Island now! Onions-R-Us is in the complete opposite direction!'
  onions-r-us: 'We\'re here! This is my favourite shop... Now try to find the pickled onions.'
  onions-zoom-out: 'Na-ah! We don\'t wanna leave till we got them pickled onions!'
  collect-onions: 'You found me onions! Beautiful. Meet me back at Ponyhead Bay.'
}

module.exports = HelpfulButtstacks = React.create-class {
  display-name: \HelpfulButtstacks

  statics:
    OverwrittenError: class OverwrittenError extends Error

  get-initial-state: -> {
    active: false
    message: ''
    button-label: 'OK'
  }

  activate: (name, button-label = 'OK') -> new Promise (resolve, reject) ~>
    @deactivate new HelpfulButtstacks.OverwrittenError "Overwritten by #name"
    message = messages[camelize name] or name
    @set-state {active: true, message, button-label}
    @_resolve = resolve
    @_reject = reject

  deactivate: (success = true) ->
    if @_resolve
      if success instanceof Error
        console.log \reject success
        @_reject success
      else @_resolve success
      @_resolve = @_reject = null

    @set-state active: false

  render: ->
    dom.div class-name: (cx \helpful-buttstacks, @state.{active}),
      dom.img src: (assets.load-asset '/minigames/urls/assets/buttstacks.png', \url)
      dom.div class-name: \speech-bubble,
        @state.message
        dom.button class-name: 'speech-bubble-dismiss btn btn-small', on-click: @deactivate,
          @state.button-label
}
