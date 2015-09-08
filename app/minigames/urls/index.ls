exports, require, module <- require.register 'minigames/urls/index'

require! {
  'lib/channels'
  'minigames/urls/URLMiniGameView'
}

const show-tutorial = true

module.exports = class URLMiniGame
  ->
    _.mixin this, Backbone.Events
    @$el = $ \#levelcontainer

  load: -> null

  create-view: (start, exit = true) ->
    @view = new URLMiniGameView {el: @$el.empty!, start, exit}
    @view.load!
    @view.start!

  start: !->
    @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
    unless show-tutorial
      @create-view \junctionPhb, false
      return

    @_main-promise = Promise.delay 500
      .cancellable!
      .then ~>
        @create-view \phb, false
        @frame-sub.pause!
      .then -> eak.start-conversation '/minigames/urls/conversations/1-intro'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
      .then ~>
        @view.map.exit!
        @view.set-target-url 'http' 'bulbous-island.com' 'onions-r-us' 'pickled-onions'
        @view.set-target-image '/minigames/urls/assets/pickled-onions.png'
        wait-for-event @view.map, \arrive
      .then ~> @start-tutorial-onions!
      .then ~> eak.start-conversation '/minigames/urls/conversations/2-flowers'
      .then ~>
        @view.set-target-url 'http' 'flee.net' 'flower-power' 'dandelions'
        @view.set-target-image '/minigames/urls/assets/dandelions.png', false
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.map.exit!
        wait-for-event @view.map, \arrive
      .then ~> @simple-tutorial \flee, 'flower-power/dandelions'
      .then ~> eak.start-conversation '/minigames/urls/conversations/3-teeth'
      .then ~>
        @view.set-target-url 'http' 'drudshire.biz' 'gum-alley' 'greasy-pete'
        # TODO @view.set-target-image
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.map.exit!
        wait-for-event @view.map, \arrive
      .then ~> @simple-tutorial \drudshire, 'gum-alley/greasy-pete'
      .then ~> eak.start-conversation '/minigames/urls/conversations/4-date-location'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.start-url-entry-mode 'http://'
        @start-date-tutorial!
      .then ~> eak.start-conversation '/minigames/urls/conversations/5-go-home'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.start-url-entry-mode 'http://'
        @start-home-tutorial!
      .then ~> eak.start-conversation '/minigames/urls/conversations/6-finish'
      .then ~> eak.trigger-async \quit

  start-tutorial-onions: ->
    var bulbous-zoom-out, onions-zoom-out

    @view.help.activate \url, 'Next'
      .then ~> @view.help.activate \domain, 'Next'
      .then ~> @view.help.activate \move, 'Got it'

    @view.map.on \before-go, before-go = (dest, prevent) ~>
      if dest in <[phb flee drudshire shackerton]>
        @view.help.activate \wrong-domain
        prevent!

    @view.url-component.set-state hidden: false

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
        @view.help.activate \collect-onions
        @view.towns.bulbous.zoomer.off \before-zoom-out onions-zoom-out
        @view.zoomer.off \before-zoom-out bulbous-zoom-out
        @view.map.off \before-go before-go
        Promise.delay 2000
      .then ~>
        @view.set-target-url 'http' 'ponyhead-bay.com'
        Promise.delay 1000
      .then ~>
        @view.url-component.set-state correct: false
        wait-for-event @view.zoomer, \before-zoom-in, condition: (loc, prevent ) ->
          if loc is \phb
            prevent!
            true
          else false
      .then ~>
        @view.help.deactivate!
        @frame-sub.pause!
        Promise.delay 2000

  simple-tutorial: (town, target) ->
    @view.url-component.set-state hidden: false, correct: false
    wait-for-event @view.towns[town], \path, condition: (path) -> path is target
      .then ~> Promise.delay 2000
      .then ~>
        @view.set-target-url 'http' 'ponyhead-bay.com'
        Promise.delay 1000
      .then ~>
        @view.url-component.set-state correct: false
        wait-for-event @view.zoomer, \before-zoom-in, condition: (loc, prevent) ->
          if loc is \phb
            prevent!
            true
          else false
      .then ~>
        @view.help.deactivate!
        @frame-sub.pause!
        Promise.delay 2000

  start-date-tutorial: ->
    check-url = ~>
      wait-for-event @view, \submit-url
        .then ([url]) ~>
          if url.match /^https?\:\/\/shackerton-by-sea.com\/.+\/?$/i
            return
          else
            unless url.match /^https?\:\/\/shackerton-by-sea.com/i
              @view.help.activate \shackerton-wrong-domain
            else @view.help.activate \shackerton-wrong-path
            check-url!

    @view.url-entry.set-state show-submit: false
    Promise.delay 500
      .then ~>
        @view.help.activate \type-url
        wait-for-event @view, \valid-url, condition: (url) -> url.0 is \shackerton
      .then ~>
        @view.help.activate \type-path
        @view.url-entry.set-state show-submit: true
        check-url!
      .then ~>
        @view.stop-url-entry-mode \junctionPhb

  start-home-tutorial: ->
    check-url = ~>
      wait-for-event @view, \submit-url
        .then ([url]) ~>
          if url.match /^https?\:\/\/ponyhead-bay.com\/park\/?$/i
            return
          else
            unless url.match /^https?\:\/\/ponyhead-bay.com/i
              @view.help.activate \phb-wrong-domain
            else @view.help.activate \phb-wrong-path
            check-url!

    @view.url-entry.set-state show-submit: false
    Promise.delay 500
      .then ~>
        wait-for-event @view, \valid-url, condition: (url) -> url.0 is \phb
      .then ~>
        @view.url-entry.set-state show-submit: true
        check-url!
      .then ~>
        @view.stop-url-entry-mode \junctionPhb

  on-frame: (t) ->
    if @view then @view.step t

  is-editable: -> false

  cleanup: ->
    if @_main-promise then @_main-promise.cancel!
    if @frame-sub then @frame-sub.unsubscribe!
    @view.remove!
    @trigger \cleanup
