start = 'Loading kitten gifs...'

messages = [
  'Still loading kitten gifs...'
  'These are some pretty heavy kittens...'
  'So many kittens to load...'
  'Meet me at the border...'
  'Are you having a nice day?'
  'KITTENS KITTENS KITTENS KITTENS'
  '...'
  '*yawns*'
  'No one believes in ducks...'
  'Unloading kittens from the lorry...'
  'Fighting off malicious smileys...'
  'Friday, Friday, getting down on Friday...'
  'Taking the Ring to Mordor...'
  'Inventing kittens...'
  'Playing with yarn...'
  'Oooh! Yarn!'
  'Loading more loading messages...'
  'Googleing more kitten gifs...'
  'Buying kittens off ebay...'
  'Capturing panda-sneezes...'
  'Time for a cup of tea...'
  'Would you like a biscuit?'
  'You know, I actually prefer dogs...'
  'Making a delicious spaghetti carbonara'
  'Sometimes we play Civ 5 all night...'
  'Gotta get my bowl...'
  'Gotta have cereal...'
  'Slowly, (so slowly) slowly!...'
  'Wanna see my Jony Ive impression?'
  'Kitten gifs intercepted by the NSA...'
  '8 minutes of battery life remaining...'
]

module.exports = class ElementLoader extends Backbone.Model
  defaults:
    stage: start
    progress: null

  initialize: ->
    int = set-interval ~>
      messages[Math.floor Math.random! * messages.length] |> @set \stage, _
    , 1500 + (Math.random! * 500)

    m, to-load <~ @on \change:toLoad

    if to-load is 0
      @trigger \done
      @set \stage ''
      clear-interval int

  start: ~>
    $el = @get \el
    $images = $el.find \img
    to-load = 0

    $images.each (i, img) ~>
      unless img.complete
        to-load++

        img.add-event-listener \load (e) ~>
          @set \toLoad (@get \toLoad) - 1

    @set \toLoad to-load
