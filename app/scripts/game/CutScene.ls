require! {
  'channels'
  'logger'
}

const vw = 960px
const vh = 720px
const v-aspect = vh / vw

translations = $ '#translations' .html! |> JSON.parse

template = ({next, html}) -> """
  <div class="cutscene-vid">
    #html
    <div class="cutscene-subtitle" id="cutscene-subtitle"></div>
  </div>
  <a href="#next" class="skip">#{translations.cutscene.skip} &rarr;</a>
"""

$util = $ '<div></div>'

module.exports = class CutScene extends Backbone.View
  tag-name: 'div'
  class-name: 'cut-scene'
  events:
    'tap .skip': 'triggerSkip'

  initialize: ({name}) ->
    @subs = []
    @name = name
    @subs[*] = channels.window-size.subscribe @resize
    @subs[*] = channels.game-commands.filter ( .command is \stop ) .subscribe @finish
    @html = translations.cutscene.loading
    $.ajax {
      url: name
      success: (html) ~>
        @html = html
        $util.html @html
        $util.find 'source' .attr 'src', '' .remove!
        @next = $util.find 'a' .attr 'href'
        @render!
      error: ~>
        console.log arguments
        channels.alert.publish msg: translations.cutscene.error
    }

  render: ->
    @$el.html template this.{html, next}

    # Prevent strange video loading bug in chrome
    @$el.find 'source' .each ->
      $el = $ this
      $el.attr 'src', "#{$el.attr 'src'}?#{Date.now!}"

    @$video-cont = @$el.find '.cutscene-vid'
    @$video = @$video-cont.find 'video'
    if @$video.length > 0
      @video = @$video .get 0 |> Popcorn
      @resize!

      @start-video!

  remove: ->
    for sub in @subs => sub.unsubscribe!
    super!

  start-video: ~>
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
    @trigger 'finish'
    @remove!
    window.location.href = @next

  trigger-skip: ~> @trigger 'skip'

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

  scaled-resize: (scale, w, h) ~>
    @$video-cont.css {
      width: scale * vw
      height: scale * vh
      top: (h - scale * vh) / 2
      left: (w - scale * vw) / 2
    }
