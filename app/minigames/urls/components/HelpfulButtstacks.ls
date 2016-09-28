exports, require, module <- require.register 'minigames/urls/components/HelpfulButtstacks'

require! {
  'assets'
}

dom = React.DOM

messages = {
  url: [
    'The writing at the bottom of the screen is a '
    dom.strong null, 'URL'
    '. A URL is an address to somewhere in the Internet Universe. It always starts with '
    dom.strong null, 'http://'
  ]
  domain: [
    'This URL shows that we want to get to Bulbous Island. The part that says '
    dom.strong null, 'bulbous-island.com'
    ' is called the '
    dom.strong null, 'domain'
    '.'
  ]
  move: [
    'Use the arrow keys to try and find '
    dom.strong null, 'Bulbous Island'
    '!'
  ]
  wrong-domain: 'Where do you thing you\'re going? That\'s not Bulbous Island!'
  bulbous: [
    'Mmmm! You can really smell those onions! See how '
    dom.strong null, 'bulbous-island.com'
    ' has a tick above it? That means it\'s time to move on to the next bit of the URL - called the '
    dom.strong null, 'path'
    '.'
  ]
  bulbous2: [
    'Try to find the '
    dom.strong null, 'path'
    ' - '
    dom.strong null, 'Onions-r-Us'
    '! They sell the best vintage pickled onions.'
  ]
  bulbous-zoom-out: 'Where ya going? You can\'t be leaving Bulbous Island now! Onions-R-Us is in the complete opposite direction!'
  onions-r-us: 'Nice work spud! Now find me my pickled onions'
  onions-zoom-out: 'Na-ah! We don\'t wanna leave till we got them pickled onions!'
  collect-onions: 'You found me onions! Beautiful. Meet me back at Ponyhead Bay.'
  flee-market: 'The dandelions are in the Flee Market!'
  flee-market-found: 'You made it! Now try and find the right stall'
  flee-zoom-out: 'Where ya going? You can\'t be leaving the Flee Market now! The dandelions are in the complete opposite direction!'
  collect-dandelions: 'They\'re beautiful! See you back at Ponyhead Bay.'
  drudshire: 'Greasy Pete lives in a town called Drudshire. I went there ten years ago to buy some onions... Disgusting.'
  drudshire-found:'Hmmm... where can Gum Alley be?'
  drudshire-zoom-out: 'Where ya going? You can\'t be leaving Gum Alley now! My teeth are in the complete opposite direction!'
  collect-teeth: 'Yippee! You found \'em! See you in Ponyhead Bay Spud'
  type-url-start: 'This is the start of a new URL. We need to finish it by putting in the address of where I’m going on my date.'
  type-url-search: 'Start by clicking the search box and typing in the domain for Shackerton By Sea.'
  type-path: 'Nearly there! Finish the URL by choosing a romantic place for my date with Dusty. I’ll leave it up to you - just press ‘Go’ when you’re done. '
  shackerton-wrong-domain: 'No no no! I want somewhere in Shackerton By Sea. It\'s the city of love, you know.'
  shackerton-wrong-path: 'That\'s not quite right... You need to say where in shackeron I\'m going!'
  phb-return: 'Click in the search box and take me home! I need to be back in my park so I can write songs about Dusty.'
  phb-wrong-domain: 'Ehh, not quite. I live in Ponyhead Bay, ya see? I\'m the Mayor, you know. Take me to Ponyhead Bay please.'
  phb-wrong-path: 'Naa, that\'s not it. I normally kip in the park. I get to keep an eye on everything that way. Take me to the park, please.'
  return-to-phb: 'Perfect! Bring them back to me at Ponyhead Bay'
}

module.exports = HelpfulButtstacks = React.create-class {
  display-name: \HelpfulButtstacks

  statics:
    OverwrittenError: class OverwrittenError extends Error

  get-initial-state: -> {
    active: false
    bottom: false
    button-label: 'OK'
    message: ''
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
    dom.div class-name: (cx \helpful-buttstacks, @state.{active, bottom}),
      dom.img src: (assets.load-asset '/minigames/urls/assets/buttstacks.png', \url)
      dom.div class-name: \speech-bubble,
        dom.div class-name: \speech-bubble-inner,
          @state.message
          dom.button class-name: 'speech-bubble-dismiss btn btn-small', on-click: @deactivate,
            @state.button-label
}
