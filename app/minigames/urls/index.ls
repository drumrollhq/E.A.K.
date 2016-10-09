exports, require, module <- require.register 'minigames/urls/index'

require! {
  'audio/music-manager'
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
    @_main-promise = music-manager.start-track 'urls-minigame'
      .then ->
        eak.play-cutscene '/cutscenes/3-urls-hello'
      .then ~>
        @frame-sub = channels.frame.subscribe ({t}) ~> @on-frame t
        unless show-tutorial
          @create-view \junctionPhb, false
          return

        @do-the-thing!

  do-the-thing: ->
    Promise.resolve!
      .cancellable!
      .then ~>
        @create-view \phb, false
        @frame-sub.pause!
      .then -> eak.start-conversation '/minigames/urls/conversations/1-intro'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
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
      .then ~> @start-dandelion-tutorial!
      .then ~> eak.start-conversation '/minigames/urls/conversations/3-teeth'
      .then ~>
        @view.set-target-url 'http' 'drudshire.biz' 'gum-alley' 'greasy-pete'
        @view.set-target-image '/minigames/urls/assets/teeth.png', false
        @view.towns.drudshire.extras.location-indicator.visible = true
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.map.exit!
        wait-for-event @view.map, \arrive
      .then ~> @start-teeth-tutorial!
      .then ~> eak.start-conversation '/minigames/urls/conversations/4-date-location'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.start-url-entry-mode 'http://'
        @start-date-tutorial!
      .then ~> eak.play-cutscene '/cutscenes/3-urls-date'
      .then ~> eak.start-conversation '/minigames/urls/conversations/5-go-home'
      .then ~>
        @frame-sub.resume!
        Promise.delay 300
      .then ~>
        @view.start-url-entry-mode 'http://'
        @start-home-tutorial!
      .then ~> eak.play-cutscene '/cutscenes/3-urls-goodbye'
      .then ~> window.location.hash = '/app/donate'

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
          .then ~> @view.help.activate \bulbous2
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

  start-dandelion-tutorial: ->
    var flee-zoom-out

    @view.help.activate \flee-market, 'Got it'

    @view.map.on \before-go, before-go = (dest, prevent) ~>
      if dest in <[phb bulbous drudshire shackerton]>
        @view.help.activate \wrong-domain
        prevent!

    @view.url-component.set-state hidden: false, correct: false

    wait-for-event @view.map, \arrive, condition: (dest) -> dest is \flee
      .then ~> wait-for-event @view.zoomer, \zoom-in
      .then ~>
        @view.help.activate \flee-market-found
        flee-zoom-out := (prevent) ~>
          @view.help.activate \flee-zoom-out
          prevent!
        @view.zoomer.on \before-zoom-out, flee-zoom-out
        wait-for-event @view.towns.flee, \path, condition: (path) -> path is 'flower-power/dandelions'
      .then ~>
        @view.help.activate \collect-dandelions
        @view.towns.flee.zoomer.off \before-zoom-out flee-zoom-out
        @view.zoomer.off \before-zoom-out flee-zoom-out
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


  start-teeth-tutorial: ->
    var drudshire-zoom-out

    @view.help.activate \drudshire, 'Got it'

    @view.map.on \before-go, before-go = (dest, prevent) ~>
      if dest in <[phb bulbous flee shackerton]>
        @view.help.activate \wrong-domain
        prevent!

    @view.url-component.set-state hidden: false, correct: false

    wait-for-event @view.map, \arrive, condition: (dest) -> dest is \drudshire
      .then ~> wait-for-event @view.zoomer, \zoom-in
      .then ~>
        @view.help.activate \drudshire-found
        drudshire-zoom-out := (prevent) ~>
          @view.help.activate \drudshire-zoom-out
          prevent!
        @view.zoomer.on \before-zoom-out, drudshire-zoom-out
        wait-for-event @view.towns.drudshire, \path, condition: (path) -> path is 'gum-alley/greasy-pete'
      .then ~>
        @view.towns.drudshire.extras.location-indicator.visible = false
        eak.play-cutscene '/cutscenes/3-urls-greasy-pete'
      .then ~>
        @view.help.activate \collect-teeth
        @view.towns.drudshire.zoomer.off \before-zoom-out drudshire-zoom-out
        @view.zoomer.off \before-zoom-out drudshire-zoom-out
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

  simple-tutorial: (town, target, on-arrive = -> null) ->
    @view.url-component.set-state hidden: false, correct: false
    wait-for-event @view.towns[town], \path, condition: (path) -> path is target
      .then ~> Promise.delay 2000
      .then ~> on-arrive!
      .then ~>
        @view.set-target-url 'http' 'ponyhead-bay.com'
        Promise.delay 1000
      .then ~>
        @view.help.activate \return-to-phb
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

    @view.help.activate \type-url-start, 'Next'
      .then ~> @view.help.activate \type-url-search, 'Got it'

    @view.url-entry.set-state show-submit: false
    Promise.delay 500
      .then ~>
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

    @view.help.activate \phb-return
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
