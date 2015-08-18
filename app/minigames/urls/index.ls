exports, require, module <- require.register 'minigames/urls/index'

require! {
  'lib/channels'
  'minigames/urls/URLMiniGameView'
}

module.exports = class URLMiniGame
  ->
    _.mixin this, Backbone.Events
    @$el = $ \#levelcontainer

  load: -> null

  create-view-at: (start, url, exit = true) ->
    @view = new URLMiniGameView {el: @$el.empty!, start, exit}
    @view.load!
    @view.start!
    @view.set-target-url ...url

  start: !->
    @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
    Promise.delay 500
      .then ~>
        @create-view-at \phb, ['http' 'bulbous-island.com' 'onions-r-us' 'pickled-onions'], false
        @frame-sub.pause!
      .then -> eak.start-conversation '/minigames/urls/conversations/1-intro'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.map.exit!
        wait-for-event @view.map, \arrive
      .then ~>
        @start-tutorial-phb!

  start-tutorial-phb: ->
    var bulbous-zoom-out, onions-zoom-out

    @view.help.activate \url, 'Next'
      .then ~> @view.help.activate \domain, 'Next'
      .then ~> @view.help.activate \move, 'Got it'

    @view.map.on \before-go, before-go = (dest, prevent) ~>
      if dest in <[phb flee drudshire schackerton]>
        @view.help.activate \wrong-domain
        prevent!

    wait-for-event @view.map, \arrive, condition: (dest) -> dest is \bulbous
      .then ~> wait-for-event @view.zoomer, \zoom-in
      .then ~>
        @view.help.activate \bulbous, 'Got it'
        bulbous-zoom-out := (prevent) ~>
          @view.help.activate \bulbous-zoom-out
          prevent!
        @view.zoomer.on \before-zoom-out, bulbous-zoom-out
        wait-for-event @view.towns.bulbous.zoomer, \zoom-in, condition: (dest) -> console.log {dest}; dest is \onionsRUs
      .then ~>
        @view.help.activate \onions-r-us
        onions-zoom-out := (prevent) ~>
          @view.help.activate \onions-zoom-out
          prevent!
        @view.towns.bulbous.zoomer.on \before-zoom-out, onions-zoom-out
        wait-for-event @view.towns.bulbous, \path, condition: (path) -> path is 'onions-r-us/pickled-onions'
      .then ~>
        @view.help.activate \collect-onions 'Got it'

  on-frame: (t) ->
    if @view then @view.step t

  is-editable: -> false

  cleanup: ->
    console.log \minigame-cleanup arguments
