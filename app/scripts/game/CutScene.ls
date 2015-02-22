require! {
  'lib/channels'
  'translations'
}

const vw = 960px
const vh = 720px
const v-aspect = vh / vw
const sleep-timeout = 3000ms

template = ({next, html}) -> """
  <div class="cutscene-vid">
    #html
    <div class="cutscene-subtitle" id="cutscene-subtitle"></div>
  </div>
  <button class="btn skip">#{translations.cutscene.skip} &rarr;</button>
"""

$util = $ '<div></div>'

module.exports = class CutScene extends Backbone.View
  tag-name: \div
  class-name: \cut-scene
  events:
    'click .skip': 'triggerSkip'
    'mousemove': 'wakeup'

  initialize: ({@name, @url}) ->
    @subs = []

  load: ->
    Promise.resolve $.ajax url: "#{@url}.html?_v=#{EAKVERSION}"
      .then (html) ~>
        @html = html
        $util.html html
        $util.find 'source' .attr 'src', '' .remove!
        @next = $util.find 'a' .attr 'href'
      .catch (e) ->
        console.error e
        throw new Error translations.cutscene.error

  save-defaults: -> {
    type: \cutscene
    url: @name
    state: {}
  }

  start: ->
    @render!
    @attach!
    @resize!
    @setup-video!
    @wakeup!

  cleanup: ->
    for sub in @subs => sub.unsubscribe!
    @remove!

  render: ->
    @$el.html template this.{html, next}

    # prevent strange video loading bug in chrome
    @$el.find 'source' .each ->
      $el = $ this
      $el.attr 'src', "#{$el.attr 'src'}?_v=#{EAKVERSION}"

    @$video-cont = @$el.find '.cutscene-vid'
    @$skip = @$el.find '.skip'
    @$video = @$video-cont.find 'video'
    if @$video.length > 0
      @video = @$video .get 0 |> Popcorn

  attach: ->
    @$el.append-to document.body
    @subs[*] = channels.window-size.subscribe @resize
    @subs[*] = channels.game-commands.filter ( .command is \stop ) .subscribe @finish

  setup-video: ~>
    @video.on 'ended' @finish

    # Set up subtitles:
    subtitle-target = @$el.find '.csst-inner'
    subtitles = $util.find '[data-start][data-end]'
    subtitles.each (i, el) ~>
      $el = $ el
      start-time = parse-float $el.attr 'data-start'
      end-time = parse-float $el.attr 'data-end'

      @video.subtitle {
        start: start-time
        end: end-time
        text: $el.text!
        target: 'cutscene-subtitle'
      }

    @video.play!

  finish: ~>
    @trigger \finish
    @trigger \next @next

  trigger-skip: ~>
    @trigger \skip
    @finish!

  wakeup: ->
    if @_sleep-timeout then clear-timeout @_sleep-timeout
    @_sleep-timeout = set-timeout @sleep, sleep-timeout
    if @asleep then @_wakeup!

  _wakeup: ->
    @asleep = false
    @$skip.remove-class 'asleep'

  sleep: ~>
    @asleep = true
    @$skip.add-class 'asleep'

  resize: ~>
    w = @$el.width!
    h = @$el.height!

    aspect = h / w
    if aspect > v-aspect
      if w > vw
        @natural-resize w, h
      else
        @scaled-resize w / vw, w, h

    else
      if h > vh
        @natural-resize w, h
      else
        @scaled-resize h / vh, w, h

  natural-resize: (w, h) ~>
    @$video-cont.css {
      width: vw
      height: vh
      top: (h - vh) / 2
      left: (w - vw) / 2
    }

    @$skip.css {
      top: 15 + (h - vh) / 2
      left: 15 + (w - vw) / 2
    }

  scaled-resize: (scale, w, h) ~>
    @$video-cont.css {
      width: scale * vw
      height: scale * vh
      top: (h - scale * vh) / 2
      left: (w - scale * vw) / 2
    }

    @$skip.css {
      top: 15 + (h - scale * vh) / 2
      left: 15 + (w - scale * vw) / 2
    }
